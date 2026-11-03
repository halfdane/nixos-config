# ./modules/storagebox.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.storagebox;

  # Runs immediately before rclone mounts. Other modules (notably nixarr's
  # systemd-tmpfiles rules) recreate an empty directory skeleton under the
  # mountpoint very early at boot, long before the network is up. rclone
  # refuses to mount over a non-empty directory, so on the next boot the mount
  # silently fails and services write downloads to the local root disk instead.
  #
  # This guard removes any *empty* directory skeleton — but only when the path
  # is not already a live mount, so we never touch the remote. Real files left
  # behind by a mis-timed download are deliberately preserved: the mount then
  # fails loudly rather than shadowing (and orphaning) local data.
  mountCleanup = mountpoint: pkgs.writeShellScript "storagebox-premount-clean" ''
    set -eu
    MP=${lib.escapeShellArg mountpoint}
    # A crashed rclone leaves a stale FUSE mount (ENOTCONN): the kernel still
    # lists it, but stat fails, so mkdir/mountpoint below would abort forever.
    # findmnt reads the mount table, not the dead mount, so it still works.
    if ${pkgs.util-linux}/bin/findmnt -rn "$MP" >/dev/null \
       && ! ${pkgs.coreutils}/bin/stat "$MP" >/dev/null 2>&1; then
      ${pkgs.util-linux}/bin/umount -l "$MP"
    fi
    ${pkgs.coreutils}/bin/mkdir -p "$MP"
    if ! ${pkgs.util-linux}/bin/mountpoint -q "$MP"; then
      ${pkgs.findutils}/bin/find "$MP" -mindepth 1 -depth -type d -empty -delete
    fi
  '';
in

{
  options.services.storagebox = {
    enable = mkEnableOption "Hetzner Storage Box mount";

    mountpoint = mkOption {
      type = types.path;
      description = "Mount point for the Storage Box.";
    };

    sshKeyPath = mkOption {
      type = types.path;
      description = "Path to the SSH private key for Storage Box access.";
    };

    server = mkOption {
      type = types.str;
      description = "Storage Box hostname.";
    };

    username = mkOption {
      type = types.str;
      description = "Username for Storage Box.";
    };

    rc = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Expose rclone's remote-control API on a loopback address (no auth) so
          local tooling can query VFS upload progress. Used by
          scripts/transcode-oversized to wait for each write-back upload to
          drain before touching the next file (overlapping transfers once
          wedged the FUSE mount). Leave off on hosts that only stream reads.
        '';
      };
      addr = mkOption {
        type = types.str;
        default = "localhost:5572";
        description = "Loopback address for the rclone RC API when rc.enable is true.";
      };
    };

    synch = {
      enable = mkEnableOption ''
        a second rclone mount of the Storage Box `synch` folder over WebDAV
        (HTTPS, port 443). The company VPN drops SFTP to the Storage Box but
        lets WebDAV through, so anything that must stay reachable from inside
        the VPN (the keepass file) should live here, not on the SFTP mount
      '';

      mountpoint = mkOption {
        type = types.path;
        default = "/mnt/synch";
        description = ''
          Mount point for the synch folder. Must not be inside the SFTP
          mountpoint: rclone refuses to mount over a non-empty directory.
        '';
      };

      username = mkOption {
        type = types.str;
        example = "u564954-sub1";
        description = "Storage Box sub-account whose home directory is the synch folder.";
      };

      server = mkOption {
        type = types.str;
        default = "${cfg.synch.username}.your-storagebox.de";
        defaultText = literalExpression ''"''${config.services.storagebox.synch.username}.your-storagebox.de"'';
        description = ''
          WebDAV hostname. Sub-accounts have their own hostname, named after
          the sub-account: the main account's host answers 401 for them.
        '';
      };

      passwordFile = mkOption {
        type = types.path;
        description = ''
          File containing the sub-account password in plain text. A trailing
          newline is ignored. The service obscures it for rclone at start.
        '';
      };
    };

    dependentServices = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "sonarr" "radarr" "sabnzbd" ];
      description = ''
        Names of systemd services (without the .service suffix) that read from
        or write to the mountpoint. Each is ordered `after` and set to
        `require` the rclone mount, so they never start — and therefore never
        write downloads to the local disk — until the Storage Box is actually
        mounted. Combined with the notify-based readiness of the mount unit,
        this eliminates the boot-time race where downloads land locally.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rclone ];

    boot.kernelModules = [ "fuse" ];

    # -------------------------------------------------------------------------
    # rclone SFTP mount at <mountpoint>
    # -------------------------------------------------------------------------
    systemd.services = lib.mkMerge [
      {
        rclone-storagebox = {
      description = "rclone SFTP mount for Hetzner Storage Box";
      after    = [ "network-online.target" ];
      wants    = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        # notify: rclone signals readiness via sd_notify only once the FUSE
        # mount is actually live, so `after`-ordered consumers wait for a real
        # mount rather than merely for the process to have been spawned.
        Type = "notify";
        ExecStartPre = "+${mountCleanup cfg.mountpoint}";
        ExecStart = pkgs.writeShellScript "rclone-storagebox-mount" ''
          exec ${pkgs.rclone}/bin/rclone mount \
            :sftp:/home \
            ${cfg.mountpoint} \
            --sftp-host=${cfg.server} \
            --sftp-port=23 \
            --sftp-user=${cfg.username} \
            --sftp-key-file=${cfg.sshKeyPath} \
            --allow-other \
            --dir-perms=0775 \
            --file-perms=0664 \
            --cache-dir=/var/cache/rclone \
            --vfs-cache-mode=full \
            --vfs-cache-max-age=72h \
            --vfs-cache-max-size=40G \
            --buffer-size=32M \
            --vfs-read-ahead=128M \
            --transfers=2 \
            --sftp-idle-timeout=60s \
            --contimeout=15s \
            --timeout=60s \
            --low-level-retries=20 \
            ${optionalString cfg.rc.enable "--rc --rc-addr=${cfg.rc.addr} --rc-no-auth \\\n            "}--log-level=INFO
        '';
        # Give rclone a real HOME so it stops erroring on the missing `getent`
        # and stores its config/cache where we expect.
        Environment = "HOME=/root";
        # systemd creates/owns /var/cache/rclone for the VFS cache (full mode:
        # caches both reads and write-back, so seeks/re-reads hit local disk
        # instead of re-fetching over SFTP — sized for ada's streaming role).
        CacheDirectory = "rclone";
        # A dead rclone turns the FUSE mount into an uninterruptible zombie that
        # hangs every consumer. Under memory pressure, tell the OOM killers to
        # sacrifice the greedy readers/writers (ffmpeg, cp) first, not rclone.
        OOMScoreAdjust = -800;
        # Detach the mount whenever rclone exits (stop or crash), so a dead
        # process never leaves a stale FUSE mount behind. `-`: best-effort.
        ExecStopPost = "-+${pkgs.util-linux}/bin/umount -l ${cfg.mountpoint}";
        Restart    = "on-failure";
        RestartSec = "10s";
      };
      # Never give up retrying during long network outages (VPN, Hetzner).
      unitConfig.StartLimitIntervalSec = 0;
        };
      }

      # -----------------------------------------------------------------------
      # rclone WebDAV mount of the synch folder (reachable through the VPN)
      # -----------------------------------------------------------------------
      (lib.mkIf cfg.synch.enable {
        rclone-synch = {
          description = "rclone WebDAV mount for Hetzner Storage Box synch folder";
          after    = [ "network-online.target" ];
          wants    = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "notify";
            ExecStartPre = "+${mountCleanup cfg.synch.mountpoint}";
            ExecStart = pkgs.writeShellScript "rclone-synch-mount" ''
              set -eu
              # rclone only accepts obscured passwords; read the plain one from
              # the secret file via stdin so it never shows up in argv.
              RCLONE_WEBDAV_PASS=$(printf '%s' "$(< ${cfg.synch.passwordFile})" | ${pkgs.rclone}/bin/rclone obscure -)
              export RCLONE_WEBDAV_PASS
              exec ${pkgs.rclone}/bin/rclone mount \
                :webdav: \
                ${cfg.synch.mountpoint} \
                --webdav-url=https://${cfg.synch.server} \
                --webdav-vendor=other \
                --webdav-user=${cfg.synch.username} \
                --allow-other \
                --dir-perms=0775 \
                --file-perms=0664 \
                --cache-dir=/var/cache/rclone-synch \
                --vfs-cache-mode=full \
                --vfs-cache-max-age=72h \
                --vfs-cache-max-size=1G \
                --dir-cache-time=30s \
                --contimeout=15s \
                --timeout=60s \
                --low-level-retries=20 \
                --log-level=INFO
            '';
            Environment = "HOME=/root";
            CacheDirectory = "rclone-synch";
            OOMScoreAdjust = -800;
            ExecStopPost = "-+${pkgs.util-linux}/bin/umount -l ${cfg.synch.mountpoint}";
            Restart    = "on-failure";
            RestartSec = "10s";
          };
          unitConfig.StartLimitIntervalSec = 0;
        };
      })

      # Order every declared consumer after a *successful* mount and require
      # it, so nothing writes to the mountpoint before the Storage Box is live.
      (lib.genAttrs cfg.dependentServices (_: {
        after    = [ "rclone-storagebox.service" ];
        requires = [ "rclone-storagebox.service" ];
      }))
    ];
  };
}


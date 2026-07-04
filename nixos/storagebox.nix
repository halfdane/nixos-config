# ./modules/storagebox.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.storagebox;
  # Media group GID as set by nixarr globals — all arr services and sabnzbd run under this group.
  # sabnzbd uid is also set by nixarr globals (38). These are stable nixarr-assigned values.
  mediaGid = toString config.users.groups.media.gid;
  sabnzbdUid = toString config.users.users.sabnzbd.uid;

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
      description = "Mount point for the Storage Box. SSHFS is mounted at <mountpoint>.sshfs.";
    };

    sshKeyPath = mkOption {
      type = types.path;
      description = "Path to the SSH private key for Storage Box access.";
    };

    server = mkOption {
      type = types.str;
      default = "u564933.your-storagebox.de";
      description = "Storage Box hostname.";
    };

    username = mkOption {
      type = types.str;
      default = "u564933";
      description = "Username for Storage Box.";
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
    environment.systemPackages = [ pkgs.sshfs pkgs.rclone ];

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
            --vfs-cache-mode=writes \
            --vfs-cache-max-age=6h \
            --vfs-cache-max-size=50G \
            --buffer-size=256M \
            --vfs-read-ahead=512M \
            --transfers=4 \
            --log-level=INFO
        '';
        Restart    = "on-failure";
        RestartSec = "10s";
      };
        };
      }

      # Order every declared consumer after a *successful* mount and require
      # it, so nothing writes to the mountpoint before the Storage Box is live.
      (lib.genAttrs cfg.dependentServices (_: {
        after    = [ "rclone-storagebox.service" ];
        requires = [ "rclone-storagebox.service" ];
      }))
    ];

    # -------------------------------------------------------------------------
    # sshfs mount at <mountpoint>.sshfs  (retained for comparison / fallback)
    # -------------------------------------------------------------------------
    fileSystems."${cfg.mountpoint}.sshfs" = {
      device = "${cfg.username}@${cfg.server}:/home";
      fsType = "fuse.sshfs";
      options = [
        "allow_other"

        # Makes mount automatically reconnect on network drop
        "reconnect"

        # Don’t hang for ages on dead connections
        "ConnectTimeout=5"
        "ServerAliveInterval=30"
        "ServerAliveCountMax=3"

        # Cache tweaks for WAN (timeouts in seconds)
        # `kernel_cache` avoids re‑reading metadata on every access
        "cache=yes"
        "kernel_cache"
        "cache_timeout=3600"   # 1h cache for attrs
        "attr_timeout=3600"   # 1h attribute cache
        "entry_timeout=3600"  # 1h dir entry cache
        "compression=yes"
        "Ciphers=aes128-ctr"

        # Don’t update atime on remote files (fewer SSH roundtrips)
        "noatime"

        # SSH port and key
        "ssh_command=ssh -p 23"
        "IdentityFile=${cfg.sshKeyPath}"

        # systemd auto‑mount
        "x-systemd.automount"
        "x-systemd.requires=network-online.target"
        "x-systemd.after=network-online.target"
        "x-systemd.requires-mounts-for=/"
      ];
    };
  };
}


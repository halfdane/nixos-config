# ./modules/storagebox.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.storagebox;
in

{
  options.services.storagebox = {
    enable = mkEnableOption "Hetzer Storage Box SSHFS mount";

    mountpoint = mkOption {
      type = types.path;
      description = "Mount point for the Storage Box share.";
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
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.sshfs ];

    boot.kernelModules = [ "fuse" ];

    fileSystems."${cfg.mountpoint}" = {
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


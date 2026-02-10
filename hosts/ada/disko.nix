{ lib, ... }: {
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = false;  # VPS firmware no vars
      efiSysMountPoint = "/boot";
    };
  };

  disko.devices = {
    disk.vda = {
      device = "/dev/vda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            name = "ESP";
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "luks-root";
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "noatime" "compress=zstd:1" "space_cache=v2" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "noatime" "compress=zstd:1" "space_cache=v2" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "noatime" "compress=zstd:1" "space_cache=v2" ];
                  };
                  "@varlog" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "noatime" "compress=zstd:1" "space_cache=v2" ];
                  };
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "noatime" "compress=zstd:1" "space_cache=v2" ];
                  };
                  "@swapfile" = {
                    mountpoint = "/swapfile";
                    mountOptions = [ "noatime" "nodatacow" "nodatasum" "space_cache=v2" ];
                  };
                  "@data" = {
                    mountpoint = "/data";
                    mountOptions = [ "noatime" "compress=zstd:1" "space_cache=v2" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Swapfile (8GB example)
  swapDevices = [{
    device = "/swapfile/swapfile";
    size = 8192;
    randomEncryption.enable = true;
  }];

  # Swapfile setup (disable CoW, create file)
  systemd.services.initrd-setup-swapfile = {
    wantedBy = [ "initrd-setup.service" ];
    before = [ "initrd-setup.service" ];
    script = ''
      chattr +C /swapfile
      truncate -s 8G /swapfile/swapfile
      mkswap /swapfile/swapfile
    '';
  };

  # Hourly Snapper on /home (prunes aggressively)
  services.snapper.configs.home = {
    SUBVOLUME = "/home";
    FSTYPE = "btrfs";
    ALLOW_USERS = [ "yourusername" ];  # Replace
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_MIN_AGE = "1800";
    TIMELINE_LIMIT_HOURLY = "5";
    TIMELINE_LIMIT_DAILY = "7";
    TIMELINE_LIMIT_WEEKLY = "4";
    TIMELINE_LIMIT_MONTHLY = "3";
  };

  # /home quota (50GB)
  # systemd.services.btrfs-home-quota = {
  #   description = "Set BTRFS quota for /home";
  #   after = [ "local-fs.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig.Type = "oneshot";
  #   script = ''
  #     btrfs quota enable /
  #     HOME_QGROUP=$(btrfs qgroup show /home | grep -o '0/[0-9]*' | head -1)
  #     btrfs qgroup create $HOME_QGROUP /
  #     btrfs qgroup limit 50G $HOME_QGROUP /
  #   '';
  # };

  # Optional: Impermanence (@persist for state)
  # Uncomment + add environment.persistence."/persist" for your files
  # fileSystems."/persist" needs UUID or label reference if needed
  # environment.persistence."/persist" = {
  #   directories = [ "/var/lib" ];
  #   files = [ "/etc/machine-id" ];
  # };
}

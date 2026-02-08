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
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                mountOptions = [ "noatime" "compress=zstd" "space_cache=v2" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                  };
                  "@home" = {
                    mountpoint = "/home";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}

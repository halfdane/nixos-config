{ config, lib, ... }: {
  disko.devices = {
    disk.disk1 = {
      type = "disk";
      device = "/dev/vda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/" = {
                  mountpoint = "/";
                  mountOptions = [ "noatime" "compress=zstd:1" "space_cache=v2" ];
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = [ "noatime" "compress=zstd:1" "space_cache=v2" ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "noatime" "compress=zstd:1" "space_cache=v2" ];
                };
                "/var/log" = {
                  mountpoint = "/var/log";
                  mountOptions = [ "noatime" "compress=zstd:1" "space_cache=v2" ];
                };
                "/persist" = {
                  mountpoint = "/persist";
                  mountOptions = [ "noatime" "compress=zstd:1" "space_cache=v2" ];
                };
                "/swapfile" = {
                  mountpoint = "/swapfile";
                  mountOptions = [ "noatime" "nodatacow" "nodatasum" "space_cache=v2" ];
                };
                "/data" = {
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
}

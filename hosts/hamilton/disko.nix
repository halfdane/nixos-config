{ config, lib, ... }: {
  disko.devices = {
    disk.disk1 = {
      type = "disk";
      device = "/dev/disk/by-id/ata-TOSHIBA_KSG60ZSE256G_SATA_256GB_Z7DS102QTXKT";
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
              type = "filesystem";
              format = "ext4";
              extraArgs = [ "-L" "nixos" ];
              mountpoint = "/";
              mountOptions = [ "noatime" ];
            };
          };
        };
      };
    };
  };
}

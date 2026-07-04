{ lib, ... }: {
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = false;
      efiSysMountPoint = "/boot";
    };
  };
  boot.initrd.availableKernelModules = [ "virtio_scsi" "virtio_blk" "virtio_pci" ];
  boot.initrd.kernelModules = [ "dm-crypt" "cryptd" ];

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
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "luks-root";
              settings.allowDiscards = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
            };
          };
        };
      };
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;  # Max 3.8G compressed
    priority = 100;
  };
  boot.kernel.sysctl."vm.swappiness" = 100;  # zram-friendly, but less eager to spill into the slow disk swap than the previous 180

}

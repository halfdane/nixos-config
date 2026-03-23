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
  boot.initrd.luks.devices."luks-root".fallbackToPassword = true;

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

  # Swapfile (8GB example)
  swapDevices = [{
    device = "/swapfile/swapfile";
    size = 8192;
    randomEncryption.enable = true;
  }];

  # Swapfile setup (now on ext4: disable CoW not needed, but truncate/mkswap)
  systemd.services.initrd-setup-swapfile = {
    wantedBy = [ "initrd-setup.service" ];
    before = [ "initrd-setup.service" ];
    script = ''
      mkdir -p /swapfile
      truncate -s 8G /swapfile/swapfile
      chattr +C /swapfile/swapfile
      mkswap /swapfile/swapfile
      chmod 600 /swapfile/swapfile
    '';
  };
}

# Hardware configuration for Apple Virtualization VM
# TODO: Generate this file by running 'nixos-generate-config --show-hardware-config'
#       inside the Apple Virtualization VM and replace this placeholder content.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Placeholder configuration - replace with actual hardware config
  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Update these filesystem paths based on your Apple VM's actual configuration
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-UUID";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-UUID";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}

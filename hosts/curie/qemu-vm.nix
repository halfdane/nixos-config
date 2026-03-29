# QEMU/UTM specific configuration
{ config, pkgs, username, hostname, ... }:
{
  # VirtFS shared folder from UTM
  fileSystems."/mnt/utm" = {
    device = "share";
    fsType = "9p";
    options = [ "trans=virtio" "version=9p2000.L" "msize=104857600" "cache=loose" "nofail" ];
  };

  # bindfs mount to remap UID/GID (macOS UID 502 -> NixOS UID 1000, macOS GID 20 -> NixOS GID 100)
  fileSystems."/home/${username}/utm" = {
    device = "/mnt/utm";
    fsType = "fuse.bindfs";
    options = [ "map=502/1000:@20/@100" "x-systemd.requires=/mnt/utm" "_netdev" "nofail" ];
  };

  # QEMU/SPICE guest agent for clipboard sharing
  services.qemuGuest.enable = true;
  virtualisation.vmVariant.virtualisation.qemu.guestAgent.enable = true;
  services.spice-vdagentd.enable = true;
  systemd.user.services.spice-vdagent = {
    description = "SPICE guest session agent";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.spice-vdagent}/bin/spice-vdagent -x";
      Restart = "always";
    };
  };
  environment.systemPackages = with pkgs; [ spice-vdagent ];
}

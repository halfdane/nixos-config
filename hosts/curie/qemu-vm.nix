# QEMU/UTM specific configuration
{ config, pkgs, username, hostname, ... }:
{
  # VirtFS shared folder from UTM.
  # Uses on-demand automount so a missing/disabled UTM share (9pnet_virtio:
  # "no channels available for device share") never fails activation/deploys.
  # Enable the share in UTM (Settings -> Sharing, mode = VirtFS) to use it.
  fileSystems."/mnt/utm" = {
    device = "share";
    fsType = "9p";
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "msize=104857600"
      "cache=loose"
      "nofail"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  # bindfs remap so the share is writable as user.
  # The 9p share exposes files with the host's macOS ownership
  # (UID 502 / GID 20); bindfs maps that to NixOS UID 1000 / GID 100.
  # Also an automount so it never blocks activation, and accessing it
  # transparently triggers the /mnt/utm automount above.
  fileSystems."/home/${username}/utm" = {
    device = "/mnt/utm";
    fsType = "fuse.bindfs";
    options = [
      "map=502/1000:@20/@100"
      "nofail"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.requires-mounts-for=/mnt/utm"
    ];
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
  environment.systemPackages = with pkgs; [ spice-vdagent bindfs ];
}

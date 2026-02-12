{ config, pkgs, lib, ... }:
{

  systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce false;
  services.navidrome = {
    enable = true;
    openFirewall = true;  # Opens port 4533
    # Optional: settings for music dir, etc.
    settings = {
      MusicFolder = "/home/halfdane/Music";
      Address = "0.0.0.0";
    };
  };


}
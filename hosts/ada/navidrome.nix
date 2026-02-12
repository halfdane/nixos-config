{ config, pkgs, lib, ... }:
{

  services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      MusicFolder = "/data/Music";
      Address = "0.0.0.0";
    };
  };


}
{ config, pkgs, lib, ... }:
{
  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/mnt/storagebox/media/music/";
      Address = "127.0.0.1";
      ND_DEFAULTPLAYLISTPUBLICVISIBILITY = true;
    };
  };

  services.nginx.virtualHosts."music.micasaestu.casa" = {
    useACMEHost = "micasaestu.casa";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:4533";
      proxyWebsockets = true;
    };
  };

}
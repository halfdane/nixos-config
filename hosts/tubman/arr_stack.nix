{ config, pkgs, lib, ... }:
{
  options.arr = {
    enable = lib.mkEnableOption "Arr*=Stack configuration";

    password = lib.mkOption {
      type = lib.types.str;
      description = "The usenet provider's password.";
    };
  };

  config = lib.mkIf config.arr.enable {

    services.prowlarr.enable = true;
    services.sonarr = { enable = true; group = "media"; openFirewall = true; };
    services.radarr = { enable = true; group = "media"; openFirewall = true; };
    services.bazarr = { enable = true; group = "media"; openFirewall = true; };

    services.sabnzbd = {
      enable = true;
      openFirewall = true;
      group = "media";
      user = "sabnzbd";
      settings = {
        misc.port = 8080;
        servers = [
          {
            name = "eweka";
            host = "news.eweka.nl";
            port = 563;  # SSL
            username = "c09545ddc163deac";
            password = config.age.secrets.eweka;
            connections = 20;
            ssl = true;
            priority = 1;
          }
        ];
      };
    };
  };
}

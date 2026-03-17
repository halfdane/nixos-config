{ config, pkgs, lib, ... }:
let domain = "micasaestu.casa"; in {

  options.arr = {
    enable = lib.mkEnableOption "Arr*=Stack configuration";

    password = lib.mkOption {
      type = lib.types.str;
      description = "The usenet provider's password.";
    };
  };

  config = lib.mkIf config.arr.enable {

    services.prowlarr.enable = true;
    services.sonarr = { enable = true; group = "media"; };
    services.radarr = { enable = true; group = "media"; };
    services.bazarr = { enable = true; group = "media"; };

    services.sabnzbd = {
      enable = true;
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

    services.nginx.virtualHosts."prowlarr.${domain}" = {
      useACMEHost = domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:9696";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."sonarr.${domain}" = {
      useACMEHost = domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8989";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."radarr.${domain}" = {
      useACMEHost = domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:7878";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."sabnzbd.${domain}" = {
      useACMEHost = domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."bazarr.${domain}" = {
      useACMEHost = domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:6767";
        proxyWebsockets = true;
      };
    };
  };
}

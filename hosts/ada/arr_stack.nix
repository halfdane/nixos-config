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
    services.sonarr.enable = true;
    services.radarr.enable = true;
    services.bazarr.enable = true;
    services.sabnzbd.enable = true;

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

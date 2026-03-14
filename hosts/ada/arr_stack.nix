{ config, pkgs, lib, ... }:
let domain = "micasaestu.casa"; in {
  services.prowlarr.enable = true;
  services.sonarr = { enable = true; group = "media"; };
  services.radarr = { enable = true; group = "media"; };

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

}

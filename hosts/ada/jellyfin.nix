{ config, pkgs, lib, ... }:
let
  domain = "micasaestu.casa";
in
{
  services.jellyfin.enable = true;
  services.jellyseerr.enable = true;

  services.nginx.virtualHosts."video.${domain}" = {
    useACMEHost = domain;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8096";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
      '';
    };
    extraConfig = "client_max_body_size 20M;";
  };

  services.nginx.virtualHosts."jellyseerr.${domain}" = {
    useACMEHost = domain;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:5055";
      proxyWebsockets = true;
    };
  };

}

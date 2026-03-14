{ config, pkgs, lib, ... }:
let
  domain = "micasaestu.casa";
  mediaDir = "/data/Videos";  # Put Ted Lasso here post-setup
in
{
  # Media group for perms
  users.groups.media = { };

  services.jellyfin = {
    enable = true;
    group = "media";
    # Data in persist/home/data for your LUKS setup
    dataDir = "/var/lib/jellyfin";
  };

  services.jellyseerr = {
    enable = true;
    configDir = "/var/lib/jellyseerr/config";  # Avoid module bugs [web:70][web:82]
  };

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

  # Perms for media dir (run once or via activation)
  systemd.tmpfiles.rules = [
    "Z ${mediaDir} media:media 0775"
  ];
}

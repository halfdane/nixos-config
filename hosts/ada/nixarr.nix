{ config, pkgs, lib, ... }:
{
  options.nixarr = {
    wgConfigPath = lib.mkOption {
      type = lib.types.path;
      description = "Path to the WireGuard configuration file.";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "micasaestu.casa";
      description = "Domain name for Nixarr's reverse proxy.";
    };
  };


  config = lib.mkIf config.nixarr.enable {
    nixarr = {
      mediaDir = "/mnt/storagebox/media/";
      stateDir = "/data/media/.state/nixarr";

      vpn = {
        enable = true;
        wgConf = config.nixarr.wgConfigPath;
      };

      sabnzbd = {
        enable = true;
        vpn.enable = true;
        # force news.eweka.nl through vpn? 
      };

      jellyfin.enable = true;
      bazarr.enable = true;
      lidarr.enable = true;
      prowlarr.enable = true;
      radarr.enable = true;
      sonarr.enable = true;
      jellyseerr.enable = true;
    };

    services.nginx.virtualHosts."video.${config.nixarr.domain}" = {
      useACMEHost = config.nixarr.domain;
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

    services.nginx.virtualHosts."jellyseerr.${config.nixarr.domain}" = {
      useACMEHost = config.nixarr.domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:5055";
        proxyWebsockets = true;
      };
    };

    services.nginx.virtualHosts."prowlarr.${config.nixarr.domain}" = {
      useACMEHost = config.nixarr.domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:9696";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."sonarr.${config.nixarr.domain}" = {
      useACMEHost = config.nixarr.domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8989";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."radarr.${config.nixarr.domain}" = {
      useACMEHost = config.nixarr.domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:7878";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."sabnzbd.${config.nixarr.domain}" = {
      useACMEHost = config.nixarr.domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:6336";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."bazarr.${config.nixarr.domain}" = {
      useACMEHost = config.nixarr.domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:6767";
        proxyWebsockets = true;
      };
    };

  };
}

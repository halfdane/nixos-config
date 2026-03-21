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
    services.sonarr = { enable = true; group = "media";};
    services.radarr = { enable = true; group = "media";};
    services.bazarr = { enable = true; group = "media";};
    services.jellyfin = { enable = true; group = "media";};
    services.jellyseerr = { enable = true;};

    services.sabnzbd = {
      enable = true;
      openFirewall = true;
      group = "media";
      settings = {
        misc = {
          host = "0.0.0.0"; # This tells SABnzbd to listen on all network interfaces
        };
      };
    };

    services.navidrome = {
      enable = true;
      group = "media";
      settings = {
        MusicFolder = "/data/media/music";
        Address = "127.0.0.1";
        ND_DEFAULTPLAYLISTPUBLICVISIBILITY = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
    services.nginx.enable = true;
    services.nginx.virtualHosts."jellyfin.tubman" = {
      serverName = "jellyfin.tubman";
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."jellyseerr.tubman" = {
      serverName = "jellyseerr.tubman";
      locations."/" = {
        proxyPass = "http://127.0.0.1:5055";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."prowlarr.tubman" = {
      serverName = "prowlarr.tubman";
      locations."/" = {
        proxyPass = "http://127.0.0.1:9696";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."sonarr.tubman" = {
      serverName = "sonarr.tubman";
      locations."/" = {
        proxyPass = "http://127.0.0.1:8989";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."radarr.tubman" = {
      serverName = "radarr.tubman";
      locations."/" = {
        proxyPass = "http://127.0.0.1:7878";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."sabnzbd.tubman" = {
      serverName = "sabnzbd.tubman";
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."bazarr.tubman" = {
      serverName = "bazarr.tubman";
      locations."/" = {
        proxyPass = "http://127.0.0.1:6767";
        proxyWebsockets = true;
      };
    };
    services.nginx.virtualHosts."music.tubman" = {
      serverName = "music.tubman";
      locations."/" = {
        proxyPass = "http://127.0.0.1:4533";
        proxyWebsockets = true;
      };
    };

    # Media group for perms
    users.groups.media = { };

    systemd.tmpfiles.rules = [
      "d /data 2775 root media - -"

      # Usenet flow
      "d /data/usenet 2775 root media - -"
      "d /data/usenet/incomplete 2775 root media - -"
      "d /data/usenet/complete 2775 root media - -"
      "d /data/usenet/complete/movies 2775 root media - -"
      "d /data/usenet/complete/tv 2775 root media - -"
      "d /data/usenet/complete/music 2775 root media - -"

      # Media libraries (Jellyfin/Navidrome scan)
      "d /data/media 2775 root media - -"
      "d /data/media/movies 2775 root media - -"
      "d /data/media/tv 2775 root media - -"
      "d /data/media/music 2775 root media - -"

      # Music manual/beets
      "d /data/music-incoming 2775 root media - -"
      "d /data/music-library 2775 root media - -"
    ];
  };
}



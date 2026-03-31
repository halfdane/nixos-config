{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.services.paperless.enable {
    services.paperless = {
      consumptionDirIsPublic = true;
      settings = {
        PAPERLESS_CONSUMER_IGNORE_PATTERN = [
          ".DS_STORE/*"
          "desktop.ini"
        ];
        PAPERLESS_OCR_LANGUAGE = "deu+eng";
        PAPERLESS_OCR_USER_ARGS = {
          optimize = 1;
          pdfa_image_compression = "lossless";
        };
        PAPERLESS_URL = "https://paperless.micasaestu.casa";
      };    
  };

    services.nginx.virtualHosts."paperless.micasaestu.casa" = {
      useACMEHost = "micasaestu.casa";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:28981";
        proxyWebsockets = true;
      };
    };

  };
}

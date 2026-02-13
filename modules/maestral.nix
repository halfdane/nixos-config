{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.maestral;
  user = cfg.user;
in {
  options.services.maestral = {
    enable = mkEnableOption "headless Maestral Dropbox sync";

    user = mkOption {
      type = types.str;
      description = "User to run service as";
    };

    dropboxPath = mkOption {
      type = types.str;
      default = "/home/${cfg.user}/Dropbox";
      description = "Local Dropbox folder path";
    };
  };

  config = mkIf cfg.enable {
    
    age.secrets = {
      "maestral.age".file = ../secrets/maestral.age;
    };

    users.users.${cfg.user}.packages = [ pkgs.maestral ];

    systemd.user.services.maestral = rec {
      description = "Headless Maestral (${cfg.dropboxPath})";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs.maestral}/bin/maestral start -f";
        ExecStop = "${pkgs.maestral}/bin/maestral stop";
        Restart = "always";
        RestartSec = 10;
      };
      preStart = ''
        mkdir -p ~/.config/maestral ${cfg.dropboxPath}

        [ -r /run/secrets/maestral ] || { echo "Missing secrets"; exit 1; }
        . /run/secrets/maestral

        ${pkgs.maestral}/bin/maestral status 2>/dev/null | grep -q "Account" || {
          echo "Linking Maestral..."
          ${pkgs.maestral}/bin/maestral auth link --refresh-token="$MAESTRAL_REFRESH_TOKEN"
        }

        ${pkgs.maestral}/bin/maestral config set path "${cfg.dropboxPath}"
      '';
    };
  };
}

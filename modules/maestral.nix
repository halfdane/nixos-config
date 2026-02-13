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
        echo "Checking if maestral is prepared..."
        ${pkgs.maestral}/bin/maestral auth status 2>/dev/null || {
          echo "Not authenticated, so starting initial setup - fetching secrets..."
          [ -r /run/secrets/maestral ] || { echo "Missing secrets"; exit 1; }
          . /run/secrets/maestral

          echo "Preparing directories..."
          mkdir -p ~/.config/maestral ${cfg.dropboxPath}

          echo "Linking Maestral..."
          ${pkgs.maestral}/bin/maestral auth link --refresh-token="$MAESTRAL_REFRESH_TOKEN"

          echo "Setting sync path to ${cfg.dropboxPath} ..."
          ${pkgs.maestral}/bin/maestral config set path "${cfg.dropboxPath}"

          echo "Initial setup finished. Ready to start."
        } && {
          echo "Everything seems fine - proceeding with actual process."
        }
      '';
    };
  };
}

{ config, lib, ... }:

let
  cfg = config.services.kde;
in {
  options.services.kde = {
    enable = lib.mkEnableOption "KDE Plasma6 desktop with SDDM";
    autoLogin = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Username for auto-login (empty = disabled)";
      example = "halfdane";
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm.enable = true;
    services.displayManager = {
      autoLogin = {
        enable = cfg.autoLogin != "";
        user = cfg.autoLogin;
      };
    };

    services.desktopManager.plasma6.enable = true;
  };
}

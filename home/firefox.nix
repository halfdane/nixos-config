{ config, pkgs, lib, ... }:
{
  config = lib.mkIf config.programs.firefox.enable {
    programs.firefox = {
      # Adopt the new XDG-based profile path (`$XDG_CONFIG_HOME/mozilla/firefox`).
      configPath = "${config.xdg.configHome}/mozilla/firefox";

      policies = {
        Extensions = {
          Install = [
            "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/addon-607454-latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/ghostery/addon-9609-latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/addon-654046-latest.xpi"
          ];
        };

        PasswordManagerEnabled = false;
        OfferToSaveLogins = false;
        OfferToSaveLoginsDefault = false;

        # Show the bookmarks bar by default
        DisplayBookmarksToolbar = "always";
      };
    };
  };
}
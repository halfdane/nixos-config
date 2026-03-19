{ config, pkgs, lib, ... }:
{
  programs.firefox = lib.mkIf config.programs.firefox.enable {
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

      # Add bookmarks
      Bookmarks = [
        {
          Title = "OG GPT";
          URL = "https://oggpt.ottogroup.com/";
          Placement = "toolbar";
        }
        {
          Title = "Ada";
          URL = "https://micasaestu.casa";
          Placement = "toolbar";
        }
      ];
    };
  };
}
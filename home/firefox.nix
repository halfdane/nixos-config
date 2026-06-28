{ config, pkgs, lib, ... }:
{
  options.programs.firefox.bookmarksfile = lib.mkOption {
    type = lib.types.path;
    description = "Path to the source bookmarks.json file in your Nix configuration. You need to manually import this file into Firefox every time you change it.";
    default = ./bookmarks.json;
    example = "input.self + /path/to/your/bookmarks.json";
  };

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

    ## whenever bookmarks change, they are actually stored in the given bookmarks.json file
    home.file."${config.xdg.userDirs.desktop}/bookmarks.json" = 
    lib.mkIf (config.programs.firefox.bookmarksfile != null && builtins.pathExists config.programs.firefox.bookmarksfile) {
       source = lib.mkForce  (
          config.lib.file.mkOutOfStoreSymlink config.programs.firefox.bookmarksfile
        );
        force = true;
     };

  };


}
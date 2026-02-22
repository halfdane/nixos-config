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
    };
  };
}


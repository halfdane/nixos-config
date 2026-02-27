{ config, lib, ... }:
let
  cfg = config.programs.kdeKeybindings;
in
{
  options.programs.kdeKeybindings = {
    enable = lib.mkEnableOption "KDE keybindings via plasma-manager";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.programs.plasma.enable;
        message = ''
          programs.kdeKeybindings.enable = true requires plasma-manager to be active.
          Set programs.plasma.enable = true on this host.
        '';
      }
    ];

    programs.plasma.shortcuts.kwin = {
      # Switch to virtual desktop N
      "Switch to Desktop 1" = "Meta+1";
      "Switch to Desktop 2" = "Meta+2";
      "Switch to Desktop 3" = "Meta+3";
      "Switch to Desktop 4" = "Meta+4";
      "Switch to Desktop 5" = "Meta+5";
      "Switch to Desktop 6" = "Meta+6";

      # Move active window to virtual desktop N
      "Window to Desktop 1" = "Meta+Shift+1";
      "Window to Desktop 2" = "Meta+Shift+2";
      "Window to Desktop 3" = "Meta+Shift+3";
      "Window to Desktop 4" = "Meta+Shift+4";
      "Window to Desktop 5" = "Meta+Shift+5";
      "Window to Desktop 6" = "Meta+Shift+6";
    };
  };
}

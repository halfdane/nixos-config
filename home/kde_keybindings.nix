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

    # Prevent accidental launcher pop-ups: Meta alone should be a plain modifier,
    # not trigger anything on release.
    programs.plasma.configFile."kwinrc"."ModifierOnlyShortcuts"."Meta" = "";

    # Meta+Return → terminal. Assumes konsole; adjust if needed.
    programs.plasma.hotkeys.commands."launch-konsole" = {
      name = "Launch Konsole";
      key = "Meta+Return";
      command = "konsole";
    };

    programs.plasma.shortcuts = {
      kwin = {
        # Switch to virtual desktop N
        "Switch to Desktop 1" = "Meta+1";
        "Switch to Desktop 2" = "Meta+2";
        "Switch to Desktop 3" = "Meta+3";
        "Switch to Desktop 4" = "Meta+4";
        "Switch to Desktop 5" = "Meta+5";
        "Switch to Desktop 6" = "Meta+6";

        # Move active window to virtual desktop N
        "Window to Desktop 1" = "Meta+Ctrl+1";
        "Window to Desktop 2" = "Meta+Ctrl+2";
        "Window to Desktop 3" = "Meta+Ctrl+3";
        "Window to Desktop 4" = "Meta+Ctrl+4";
        "Window to Desktop 5" = "Meta+Ctrl+5";
        "Window to Desktop 6" = "Meta+Ctrl+6";

        # Window management (i3-style)
        "Window Close"      = "Meta+Shift+Q";
        "Window Fullscreen" = "Meta+F";
        "Show Desktop"      = [];  # clear Meta+D; reassigned to launcher below
      };

      # Meta+D → app launcher (replaces dmenu/rofi muscle memory)
      "plasmashell"."activate application launcher" = "Meta+D";

      # Disable Meta+E silently opening Dolphin
      "org.kde.dolphin.desktop"."_launch" = [];
    };
  };
}

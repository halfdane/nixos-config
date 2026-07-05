{ config, lib, ... }:
let
  cfg = config.programs.plasma_hacking;
in
{
  options.programs.plasma_hacking = {
    enable = lib.mkEnableOption "Plasma configuration and hotkey overrides for hacking productivity";
    virtualDesktopsCount = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Number of KDE virtual desktops to configure.";
      example = 4;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.programs.plasma.enable;
        message = ''
          programs.plasma_hacking.enable = true requires plasma-manager to be active.
          Set programs.plasma.enable = true on this host.
        '';
      }
    ];

    programs.plasma = {
      # remove everything manual and let plasma-manager take care of it
      overrideConfig = true;

      configFile = {
        kscreenlockerrc.Daemon.Autolock = false;
        kscreenlockerrc.Daemon.LockOnResume = false;
        kscreenlockerrc.Daemon.LockOnStart = false;
        kscreenlockerrc.Daemon.RequirePassword = false;
        kscreenlockerrc.Daemon.Timeout = 0;
        ksmserverrc.General.confirmLogout = false;
        ksmserverrc.General.loginMode = "emptySession";
      };

      powerdevil = {
        AC = {
          turnOffDisplay = {
            idleTimeout = "never";
          };

          # Equivalent of the "Manually block sleep and screen locking" tray
          # toggle: never auto-suspend and ignore lid close (screen locking is
          # disabled via kscreenlockerrc above). Set declaratively because the
          # applet toggle is not a persistable plasma-manager / powerdevilrc
          # setting.
          autoSuspend.action = "nothing";
          whenLaptopLidClosed = "doNothing";
        };
      };

      workspace = {
        colorScheme = "BreezeDark";
        theme = "breeze-dark";
      };
      kwin.virtualDesktops.number = 6;
      kwin.virtualDesktops.rows = 2;

      # ---------------------
      # KWALLET
      # ---------------------

      # Disable KWallet — gnome-keyring is used instead as the Secret Service
      # provider, so KWallet should not compete or prompt for its own password.
      configFile."kwalletrc"."Wallet"."Enabled" = false;
      configFile."kwalletrc"."Wallet"."First Use" = false;

      # ---------------------
      # SHORTCUTS
      # ---------------------

      # Prevent accidental launcher pop-ups: Meta alone should be a plain modifier,
      # not trigger anything on release.
      configFile."kwinrc"."ModifierOnyShortcuts"."Meta" = "";

      # Meta+Return → terminal. Assumes konsole; adjust if needed.
      hotkeys.commands."launch-konsole" = {
        name = "Launch Konsole";
        key = "Meta+Return";
        command = "konsole";
      };

      shortcuts = {
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
          "Window Maximize" = "Meta+F";
          "Show Desktop"      = [];  # clear Meta+D; reassigned to launcher below

          "Activate Window Demanding Attention" = "Meta+U";
        };

        # Meta+D → app launcher (replaces dmenu/rofi muscle memory)
        "plasmashell"."activate application launcher" = "Meta+D";

        # Disable Meta+E silently opening Dolphin
        "org.kde.dolphin.desktop"."_launch" = [];
      };


      # ----------------------
      # TASK BAR
      # ----------------------

      

    };
  };
}

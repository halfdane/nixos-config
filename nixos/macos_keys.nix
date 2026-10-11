{ config, lib, username, ... }:

# macOS-style clipboard keys via xremap.
#
# - Meta+C / Meta+V / Meta+X send Ctrl+C / Ctrl+V / Ctrl+X in normal apps.
# - In terminals they send Ctrl+Shift+C / Ctrl+Shift+V, so Ctrl+C keeps
#   sending SIGINT. Cut has no meaning in a terminal, so Meta+X copies.
# - exact_match keeps Meta+Shift+V free for Klipper (see home/plasma_hacking.nix).
#
# Lives at NixOS level because xremap needs uinput and the input/uinput groups.
# The xremap flake module sets those up for userName when serviceMode = "user".
# KDE Wayland window tracking only works in user mode.
#
# Debug: journalctl --user -u xremap -f prints the active window class.
let
  cfg = config.services.macos_keys;
in
{
  options.services.macos_keys = {
    enable = lib.mkEnableOption "macOS-style Meta+C/V/X clipboard keys (xremap)";
    terminalClasses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "konsole" "kitty" "wezterm" "ghostty" "alacritty" "foot" ];
      description = ''
        Substrings of window classes treated as terminals.
        Matched case-insensitively against the class xremap reports.
      '';
    };
  };

  config = lib.mkMerge [
    {
      # The xremap module is imported on every host (flake.nix) and warns when
      # enable is left at its default. Set it explicitly to silence that.
      services.xremap.enable = lib.mkDefault cfg.enable;
    }
    (lib.mkIf cfg.enable {
      services.xremap = {
        serviceMode = "user";
        userName = username;
        withKDE = true;
        config.keymap = [
          # First matching rule wins, so the terminal rule must come first.
          {
            name = "macos-clipboard-terminal";
            exact_match = true;
            application.only = [ "/(?i)(${lib.concatStringsSep "|" cfg.terminalClasses})/" ];
            remap = {
              "Super-c" = "C-Shift-c";
              "Super-v" = "C-Shift-v";
              "Super-x" = "C-Shift-c";
            };
          }
          {
            name = "macos-clipboard-default";
            exact_match = true;
            remap = {
              "Super-c" = "C-c";
              "Super-v" = "C-v";
              "Super-x" = "C-x";
            };
          }
        ];
      };
    })
  ];
}

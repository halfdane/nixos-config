{ config, lib, pkgs, ... }:
let
  cfg = config.programs.fonts;
  fontName = "JetBrainsMono Nerd Font";
in
{
  options.programs.fonts.enable = lib.mkEnableOption "Nerd Font for terminal icons (neovim etc.), also set as Konsole's font";

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      fonts.fontconfig.enable = true;
    }
    # Konsole profile is managed by plasma-manager.
    (lib.mkIf config.programs.plasma.enable {
      programs.konsole = {
        enable = true;
        defaultProfile = "Nerd";
        profiles.Nerd.font = {
          name = fontName;
          size = 11;
        };
      };
    })
  ]);
}

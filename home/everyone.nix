{ config, pkgs, ... }:
{
  home.stateVersion = "25.11";

  # Shell configuration
  home.sessionPath = [ "~/bin" ];

  programs.bash.enable = true;

  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = ''
      # Load parent .envrc files automatically
      source_up_if_exists
    '';
  };

  # Editor setup
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  # Version control
  programs.git.enable = true;
}

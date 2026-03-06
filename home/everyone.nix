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
    config = {
      global.hide_env_diff = true;
    };
    stdlib = ''
      # Load parent .envrc files automatically
      source_up_if_exists

      # fish 4.x made 'version' read-only; nix dev shells export it, causing
      # a harmless but noisy warning. Wrap use_flake to unset it after load.
      eval "$(declare -f use_flake | sed 's/^use_flake (/_use_flake_inner (/')"
      use_flake() { _use_flake_inner "$@"; unset version; }
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

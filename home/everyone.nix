{ config, pkgs, ... }:
{
  home.stateVersion = "25.11";

  # Shell configuration
  home.sessionPath = [ "$HOME/bin" "$HOME/.local/bin" ];

  programs.bash.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
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
    '';
  };

  # Editor setup
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  # Version control
  programs.git.enable = true;

  home.file.".taskrc.yml".text = ''
    interactive: true
  '';

  home.packages = with pkgs; [
    uv
  ];

}

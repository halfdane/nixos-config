{ config, pkgs, inputs, lib, ... }:
{
  home.stateVersion = "25.11";

  # Add ~/bin to PATH
  home.sessionPath = [ "~/bin" ];

  home.packages = with pkgs; [
        pkgs.htop
        pkgs.curl
        pkgs.direnv
        pkgs.sqlite
        pkgs.fzf
    ];

  # Enable bash to source Home Manager session variables
  programs.bash = {
    enable = true;
  };

  # Fish shell - modern shell with better defaults
  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
    ];
  };

  # Enable direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    
    # Automatically load .envrc from parent directories
    stdlib = ''
      # Load parent .envrc files automatically
      source_up_if_exists
    '';
  };

  programs.git = {
    enable = true;
  };

  
  home.file."bin/nrs" = {
    text = ''
      #!/usr/bin/env bash
      cd ~/nixos-config
      git add .
      sudo nixos-rebuild switch --flake .#laptop
    '';
    executable = true;
  };

  home.file."bin/nrst" = {
    text = ''
      #!/usr/bin/env bash
      cd ~/nixos-config
      git add .
      sudo nixos-rebuild switch --flake .#laptop
      ls ~/work/.envrc
      ls ~/halfdane/.envrc
    '';
    executable = true;
  };

}

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

  # Custom scripts
  home.file."bin/nrs" = {
    text = ''
      #!/usr/bin/env bash
      # Rebuild NixOS and commit changes
      cd ~/nixos-config
      git add .
      sudo nixos-rebuild switch --flake .#laptop
    '';
    executable = true;
  };

  home.file."bin/nrst" = {
    text = ''
      #!/usr/bin/env bash
      # Rebuild NixOS, then list .envrc files
      cd ~/nixos-config
      git add .
      sudo nixos-rebuild switch --flake .#laptop
      ls ~/work/.envrc
      ls ~/halfdane/.envrc
    '';
    executable = true;
  };
}

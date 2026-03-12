{ config, pkgs, lib, ... }:
{
  programs.vscode = lib.mkIf config.programs.vscode.enable {
    profiles.default.extensions = with pkgs.vscode-extensions; [
      ms-python.python
      jnoortheen.nix-ide
      rust-lang.rust-analyzer
      ms-vscode.makefile-tools
      mads-hartmann.bash-ide-vscode
      mkhl.direnv
      svelte.svelte-vscode
      bradlc.vscode-tailwindcss
      k--kato.intellij-idea-keybindings
    ];
  };

  ## whenever vscode changes anything, the settings are actually stored in ./vscode_settings.json
  home.file."${config.xdg.configHome}/Code/User/settings.json" = 
    lib.mkIf config.programs.vscode.enable
    {
      source = lib.mkForce  (
        config.lib.file.mkOutOfStoreSymlink /home/user/nixos-config/home/vscode_settings.json
      );
      force = true;
    };
}


{ config, pkgs, lib, ... }:
{
  programs.vscode = lib.mkIf config.programs.vscode.enable {
    profiles.default.extensions = with pkgs.vscode-extensions; [
      ms-python.python
      jnoortheen.nix-ide
      rust-lang.rust-analyzer
      github.vscode-github-actions
      ms-vscode.makefile-tools
      mads-hartmann.bash-ide-vscode
      vue.vscode-typescript-vue-plugin
      # Add or remove extensions as needed
    ];
  };
}

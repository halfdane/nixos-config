{ config, pkgs, lib, ... }:
{
  programs.vscode = lib.mkIf config.programs.vscode.enable {
    profiles.default.enableUpdateCheck = false;
    profiles.default.enableExtensionUpdateCheck = false;

    profiles.default.extensions = with pkgs.vscode-extensions; [
      ms-python.python
      jnoortheen.nix-ide
      rust-lang.rust-analyzer
      github.vscode-github-actions
      ms-vscode.makefile-tools
      mads-hartmann.bash-ide-vscode
      mkhl.direnv
      svelte.svelte-vscode
      bradlc.vscode-tailwindcss
      k--kato.intellij-idea-keybindings
    ];

    profiles.default.userSettings = {
      "rust-analyzer.server.path" = "rust-analyzer";
      "files.autoSave" = "afterDelay";
      "chat.instructionsFilesLocations" = {
        "~/global-instructions" = true;
      };
      "explorer.confirmDragAndDrop" = false;
      "svelte.enable-ts-plugin" = true;
    };
  };
}


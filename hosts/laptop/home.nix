{ config, pkgs, inputs, lib, ... }:
let
  userConfig = import ../../user-config.nix;
  username = userConfig.username;
  homeDir = "/home/${username}";
in

{
  home.packages = with pkgs; [ home-manager ];
  imports = [ ./work-config.nix ];

  home.username = userConfig.username;
    home.stateVersion = "25.11";

  # Host-specific git configuration
  programs.git = {
    enable = true;
    settings = {
      user.name = userConfig.personalGitName;
      user.email = userConfig.personalGitEmail;
      init.defaultBranch = "main";
      credential.helper = "!${pkgs.gh}/bin/gh auth git-credential";
    };
  };

  # Direnv config for personal directory (auto-switch to personal gh account)
  home.file."halfdane/.envrc".text = ''
    # Auto-switch to personal GitHub account when entering this directory
    gh auth switch --user ${userConfig.personalGitAccount}
  '';

  # Clone personal repositories script
  home.file."bin/clone-personal-repos".text = ''
    #!/usr/bin/env bash
    set -e
    echo "Switching to personal GitHub account..."
    gh auth switch --user ${userConfig.personalGitAccount} || {
      echo "Personal account not found. Please add it first:"
      echo "  gh auth login --web"
      exit 1
    }
    PERSONAL_DIR="${homeDir}/halfdane"
    mkdir -p "$PERSONAL_DIR"
    repos=(
      ${lib.concatMapStringsSep "\n      " (repo: ''"${repo}"'') userConfig.personalRepos}
    )
    for repo in $repos; do
      repo_name=$(basename "$repo" .git)
      if [ ! -d "$PERSONAL_DIR/$repo_name" ]; then
        echo "Cloning $repo_name..."
        gh repo clone "$repo" "$PERSONAL_DIR/$repo_name"
      else
        echo "$repo_name already exists, skipping"
      fi
    done
  '';
  home.file."bin/clone-personal-repos".executable = true;

}

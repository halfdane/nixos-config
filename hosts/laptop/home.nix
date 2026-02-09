{ config, pkgs, inputs, lib, ... }:
let
  userConfig = import ./user-config.nix;
  username = userConfig.username;
  homeDir = "/home/${username}";
in

{
  home.packages = with pkgs; [ 
    home-manager 
    kdePackages.kate
    kdePackages.kdeconnect-kde
    vscode
    keepassxc
    chromium
    pkgs.maestral
    pkgs.maestral-gui
    pkgs.gh
  ];

  home.username = userConfig.username;

  # Global Git configuration
  programs.git = {
    enable = true;
    settings = {
      user.name = userConfig.github.personal.name;
      user.email = userConfig.github.personal.email;
      init.defaultBranch = "main";
      credential.helper = "!${pkgs.gh}/bin/gh auth git-credential";
    };
  };

  imports = [
    (import ./github-account.nix {
      githubConfig = userConfig.github.personal;
      homeDir = homeDir;
    })
    (import ./github-account.nix {
      githubConfig = userConfig.github.work;
      homeDir = homeDir;
    })
    ../../modules/clone-repos.nix
  ];

    # Direnv config for work directory (auto-switch to work gh account)
  home.file."${userConfig.github.work.directory}/.envrc".text = ''
    # Auto-switch to work GitHub account when entering this directory
    gh auth switch --user ${userConfig.github.work.account}
    
    # Set Git identity via environment variables
    export GIT_AUTHOR_NAME="${userConfig.github.work.name}"
    export GIT_AUTHOR_EMAIL="${userConfig.github.work.email}"
    export GIT_COMMITTER_NAME="${userConfig.github.work.name}"
    export GIT_COMMITTER_EMAIL="${userConfig.github.work.email}"
  '';

    # Direnv config for work directory (auto-switch to work gh account)
  home.file."${userConfig.github.personal.directory}/.envrc".text = ''
    # Auto-switch to work GitHub account when entering this directory
    gh auth switch --user ${userConfig.github.personal.account}
  '';

}

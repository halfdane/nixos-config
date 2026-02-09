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

}

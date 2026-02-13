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
      core = {
        sshCommand = "ssh -i ${config.age.secrets."github-personal.age".path} -o IdentitiesOnly=yes";
      };
    };
    includes = [
      {
        condition = "gitdir:~/work/**";
        contents ={
          user = {
            name = "${userConfig.github.work.name}";
            email = "${userConfig.github.work.email}";
          };
          core = {
            sshCommand = "ssh -i ${config.age.secrets."github-work.age".path} -o IdentitiesOnly=yes";
          };
        };
      }
    ];
  };

  imports = [
    (import ./github-account.nix {
      githubConfig = userConfig.github.personal;
    })
    (import ./github-account.nix {
      githubConfig = userConfig.github.work;
    })
    (import ./github-account.nix {
      githubConfig = userConfig.github.system;
    })
    ../../modules/clone-repos.nix
  ];

}

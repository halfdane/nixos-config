{ config, pkgs, lib, ... }:
let
  userConfig = import ./user-config.nix;
  username = userConfig.username;
  homeDir = "/home/${username}";
in

{
  age.secrets = {
    "github-personal.age" = {
      file = ./../../secrets/github-personal.age;
    };
    "github-work.age" = {
      file = ./../../secrets/github-work.age;
    };
  };

  programs.plasma.enable = true;
  programs.plasma.kscreenlocker.autoLock = false;
  programs.plasma.kscreenlocker.lockOnResume = false;
  programs.plasma.kscreenlocker.lockOnStartup = false;
  programs.plasma.kscreenlocker.passwordRequired = false;
  programs.plasma.configFile.kscreenlockerrc = {
    Daemon = {
      Autolock = false;
    };
  };

  home.packages = with pkgs; [ 
    home-manager 
    kdePackages.kate
    kdePackages.kdeconnect-kde
    vscode
    keepassxc
    chromium
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


}

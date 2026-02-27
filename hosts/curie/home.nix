{ config, pkgs, inputs, lib, ... }:
let
  userConfig = import ./user-config.nix;
  username = userConfig.username;
  homeDir = "/home/${username}";
in

{
  age = {
    identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    secrets = {
      github-personal.file = ./../../secrets/github-personal.age;
      github-work.file = ./../../secrets/github-work.age;
      personal_ssh.file = ./../../secrets/personal_ssh.age;
    };
  };

  programs.vscode.enable = true;
  programs.firefox.enable = true;
  programs.ssh.enable = true;  
  programs.chromium.enable = true;
  programs.plasma_hacking.enable = true;

  programs.plasma = {
    enable = true;
    kscreenlocker.autoLock = false;
    kscreenlocker.lockOnResume = false;
    kscreenlocker.lockOnStartup = false;
    kscreenlocker.passwordRequired = false;
    configFile.kscreenlockerrc = {
      Daemon = {
        Autolock = false;
      };
    };
  };


  home.packages = with pkgs; [ 
    home-manager 
    kdePackages.kdeconnect-kde
    keepassxc
    seahorse
    libsecret
  ];

  home.username = userConfig.username;

  programs.git = {
    enable = true;
    settings = {
      user.name = userConfig.github.personal.name;
      user.email = userConfig.github.personal.email;
      init.defaultBranch = "main";
      core = {        
        sshCommand = "ssh -i ${config.age.secrets.github-personal.path} -o IdentitiesOnly=yes";      
      };
    };
    includes = [
      {
        condition = "gitdir:~/work/**";
        contents ={          
          user.name = "${userConfig.github.work.name}";            
          user.email = "${userConfig.github.work.email}";                 
          core = {            
            sshCommand = "ssh -i ${config.age.secrets.github-work.path} -o IdentitiesOnly=yes";          
          };
        };
      }
    ];
  };

}

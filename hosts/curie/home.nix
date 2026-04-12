{ config, pkgs, inputs, lib, username, ... }:
let
  userConfig = import ./user-config.nix;
in
{
  age = {
    identityPaths = [ "/run/agenix/user-ssh-key" ];
    secrets = {
      github-personal.file = ./../../secrets/github-personal.age;
      github-work.file = ./../../secrets/github-work.age;
    };
  };

  programs.vscode.enable = true;
  programs.firefox = { 
    enable = true; 
    bookmarksfile = ./bookmarks.json;
  };
  programs.ssh.enable = true;  
  programs.chromium.enable = true;
  
  programs.plasma_hacking.enable = true;
  programs.plasma.enable = true;

  home.packages = with pkgs; [ 
    home-manager 
    kdePackages.kdeconnect-kde
    keepassxc
    libsecret
    supersonic
    voxtype
    vlc
  ];

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

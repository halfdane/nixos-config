{ config, pkgs, inputs, lib, username, ... }:
let
  logsmith = pkgs.callPackage ../../pkgs/logsmith { };
in
{
  age = {
    identityPaths = [ "/run/agenix/user-ssh-key" ];
    secrets = {
      github-personal.file = "${inputs.secrets}/github-personal.age";
      github-work.file = "${inputs.secrets}/github-work.age";
    };
  };

  programs.vscode.enable = true;
  programs.firefox.enable = true;
  programs.ssh.enable = true;  
  programs.chromium.enable = true;
  
  programs.plasma_hacking.enable = true;
  programs.plasma.enable = true;

  programs.agents.enable = true;

  home.packages = with pkgs; [ 
    home-manager 
    github-copilot-cli
    logsmith
    kdePackages.kdeconnect-kde
    keepassxc
    libsecret
    supersonic
    voxtype
    vlc
    unzip
    obsidian
    opencode
    inkscape
    awscli2
    tuxedo
  ];

  programs.git = {
    enable = true;
    settings = {
      user.name = "halfdane";
      user.email = "REDACTED_PERSONAL_EMAIL";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      core = {        
        sshCommand = "ssh -i ${config.age.secrets.github-personal.path} -o IdentitiesOnly=yes";      
      };
    };
    includes = [
      {
        condition = "gitdir:~/work/**";
        contents ={          
          user.name = "REDACTED_WORK_NAME";            
          user.email = "REDACTED_WORK_EMAIL";
          core = {            
            sshCommand = "ssh -i ${config.age.secrets.github-work.path} -o IdentitiesOnly=yes";          
          };
        };
      }
    ];
  };

}

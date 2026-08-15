{ config, pkgs, inputs, lib, username, ... }:
let
  logsmith = pkgs.callPackage ../../pkgs/logsmith { };
  gitId = import "${inputs.secrets}/git-identities.nix";
in
{
  age = {
    identityPaths = [ "/run/agenix/user-ssh-key" ];
    secrets = {
      github-personal.file = "${inputs.secrets}/github-personal.age";
      github-work.file = "${inputs.secrets}/github-work.age";
    };
  };

  # Dedicated alias so the otto-ec work key is selected by hostname, not by
  # cwd/gitdir (Nix's flake-input git fetcher clones outside ~/work/, so the
  # gitdir:~/work/** include below never applies to it).
  programs.ssh.settings."github-otto-ec" = {
    HostName = "github.com";
    User = "git";
    IdentityFile = config.age.secrets.github-work.path;
    IdentitiesOnly = "yes";
  };

  programs.vscode.enable = true;
  programs.firefox.enable = true;
  programs.ssh.enable = true;  
  programs.chromium.enable = true;
  
  programs.plasma_hacking.enable = true;
  programs.plasma.enable = true;

  programs.agents.enable = true;
  programs.minerva.enable = true;

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
    obsidian
    opencode
    inkscape
    tuxedo
    fanficfare
    # awscli2 and unzip come from the minerva_owl-setup module (~/work/minerva/minerva_owl-setup)
  ];

  # FanFicFare CLI config. include_images defaults off, but the royalroad.com
  # adapter crashes (AttributeError on None.startswith) when a cover image is
  # present and include_images is off, so force it on for that site.
  home.file.".fanficfare/personal.ini".text = ''
    [www.royalroad.com]
    include_images:true
  '';

  programs.git = {
    enable = true;
    settings = {
      user.name = gitId.personal.name;
      user.email = gitId.personal.email;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      core.sshCommand = "ssh -i ${config.age.secrets.github-personal.path} -o IdentitiesOnly=yes";
    };
    includes = [{
      condition = "gitdir:~/work/**";
      contents = {
        user.name = gitId.work.name;
        user.email = gitId.work.email;
        core.sshCommand = "ssh -i ${config.age.secrets.github-work.path} -o IdentitiesOnly=yes";
      };
    }];
  };

}

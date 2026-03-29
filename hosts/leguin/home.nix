{ config, pkgs, inputs, lib, username, ... }:
{
  age = {
    identityPaths = [ "/run/agenix/user-ssh-key" ];
  };

  programs.firefox = { 
    enable = true; 
  };
  
  programs.plasma_hacking.enable = true;
  programs.plasma.enable = true;

  home.packages = with pkgs; [ 
    home-manager 
    kdePackages.kdeconnect-kde
    keepassxc
    libsecret
    vlc
  ];

}

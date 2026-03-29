{ config, pkgs, inputs, lib, ... }:
{

  age = {
    identityPaths = [ "/run/agenix/user-ssh-key" ];
    secrets = {
      home_wlan = {
        file = ./../../secrets/home_wlan.age;
        path = "/etc/NetworkManager/system-connections/home-wlan";
        mode = "0600";
      }; 
    };
  };

  programs.firefox.enable = true;

  programs.ssh.enable = true;  
  programs.chromium.enable = true;
  programs.plasma_hacking.enable = true;

  programs.plasma.enable = true;

  home.packages = with pkgs; [ 
    home-manager 
    kdePackages.kdeconnect-kde
    keepassxc
    libsecret
  ];
}

{ config, pkgs, agenix, ... }:

{
  environment.systemPackages = with pkgs; [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    jq
    curl
    wget
    direnv
    vim
    screen
  ];

  environment.variables.EDITOR = "vim";

  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  systemd.network.wait-online.enable = false;
  
  system.stateVersion = "25.11";
}

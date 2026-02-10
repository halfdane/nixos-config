{ config, pkgs, agenix, ... }:

{
  environment.systemPackages = with pkgs; [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    jq
    yq
    python3
    htop
    curl
    wget
    direnv
    sqlite
    fzf
    rage
    vim
    tailscale
    screen
  ];

  environment.variables.EDITOR = "vim";

  # Use the reusable Tailscale module
  tailscale = {
    enable = true;
    authKeyFile = config.age.secrets."secrets/tailscale-invite.age".path;
  };

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
  
  system.stateVersion = "25.11";
}

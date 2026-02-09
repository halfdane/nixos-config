{ config, pkgs, agenix, ... }:

{
  environment.systemPackages = with pkgs; [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    jq
    yq
    python3
    htop
    curl
    direnv
    sqlite
    fzf
    rage
    vim
    tailscale
  ];

  environment.variables.EDITOR = "vim";

  # Use the reusable Tailscale module
  tailscale = {
    enable = true;
    authKeyFile = config.age.secrets."secrets/tailscale-invite.age".path;
  };
  
  system.stateVersion = "25.11";
}

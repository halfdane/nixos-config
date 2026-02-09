{ config, pkgs, agenix, ... }:
{
  environment.systemPackages = with pkgs; [
    agenix.packages.${stdenv.hostPlatform.system}.default
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

  # Use the reusable Tailscale module
  tailscale = {
    enable = true;
    authKeyFile = config.age.secrets."secrets/tailscale-invite.age".path;
  };

}

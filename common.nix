{ pkgs, agenix, ... }:
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
  ];

}

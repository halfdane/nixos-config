{ config, pkgs, lib, ... }:

let
  homer = pkgs.stdenv.mkDerivation rec {
    pname = "homer";
    version = "v25.11.1";

    src = pkgs.fetchzip {
      url = "https://github.com/bastienwirtz/homer/releases/download/${version}/homer.zip";
      sha256 = "0g3kz5jh4bx89322b226akmx4006fvs8h35prwg9qcjlvnbrwlkc";
      stripRoot = false;
    };

    configFile = ./config.yml;

    installPhase = ''
      mkdir -p $out/assets
      cp -r ${./assets}/* $out/assets/
      cp ${./config.yml} $out/assets/config.yml
      cp -r ${pkgs.homer}/* $out/
    '';
  };
in {
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."micasaestu.casa" = {
      # Use the wildcard cert issued by acme.nix.
      useACMEHost = "micasaestu.casa";
      # Redirect plain HTTP to HTTPS.
      forceSSL = true;
      # Also respond to the host-specific subdomain.
      serverAliases = [ "ada.micasaestu.casa" ];
      root = homer;
      locations."/" = { index = "index.html"; };
    };
  };

  # No firewall rules needed here — tailscale0 is a trusted interface
  # (see nixos/tailscale.nix), so nginx is reachable over tailnet automatically.
}

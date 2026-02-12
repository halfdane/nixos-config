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
      cp ${configFile} assets/config.yml
      cp -r . $out
    '';
  };
in {
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."ada" = {
      root = homer;
      locations."/" = { index = "index.html"; };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}

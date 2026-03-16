{ config, pkgs, lib, ... }:
{

  options.usenet = {
    enable = lib.mkEnableOption "Usenet VPN configuration (e.g. for privatebin)";

    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the VPN's private key (e.g. an agenix secret).";
    };
  };

  config = lib.mkIf config.usenet.enable {

    # networking.wg-quick.interfaces.wg-privado = {
    #   address = [ "100.64.37.239/32" ];
    #   privateKeyFile = config.usenet.privateKeyFile;
    #   dns = [ "198.18.0.1" "198.18.0.2" ];

    #   postUp = ''
    #     ${pkgs.systemd}/bin/resolvectl dns wg-privado 198.18.0.1 198.18.0.2
    #   '';
    #   preDown = ''resolvectl revert wg-privado'';

    #   peers = [{
    #     publicKey = "KgTUh3KLijVluDvNpzDCJJfrJ7EyLzYLmdHCksG4sRg=";
    #     endpoint = "91.148.236.64:51820";
    #     persistentKeepalive = 25;
    #     allowedIPs = [
    #       "91.148.236.64/32"     # VPN endpoint
    #       "81.171.92.204/32"     # Eweka news
    #       "81.171.92.219/32"
    #       "81.171.92.233/32"
    #       "185.90.196.70/32"
    #       "81.171.92.0/24"
    #     ];
    #   }];
    # };
  };
}
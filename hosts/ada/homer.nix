{ config, pkgs, lib, ... }:

{
  services.homer = {
    enable = true;
    settings = {
      title = "ada Dashboard";
      logo = "assets/logo.png";
      services = [{
        name = "Hosting";
        items = [
          { name = "Navidrome"; logo = "assets/navidrome.png"; url = "http://navidrome.ada"; }
          { name = "Tailscale"; logo = "assets/tailscale.png"; url = "https://login.tailscale.com"; }
        ];
      }];
    };
    virtualHost = {
      domain = "ada";  # Creates vhost "ada" instead of default "homer"
      # Optional nginx overrides:
      nginx = {
        enable = true;  # Ensure nginx enabled
        # addSSL = true;  # HTTPS later
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}

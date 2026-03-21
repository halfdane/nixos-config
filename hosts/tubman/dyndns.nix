{ config, pkgs, lib, ... }:
{

  options.dyndns = {
    enable = lib.mkEnableOption "Enable automatic DynDNS updates for deSEC.";

    secretTokenPath = lib.mkOption {
      type = lib.types.path;
      description = "Path to the private key for authenticating with deSEC (e.g. an agenix secret).";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to update (e.g. micasaestu.dedyn.io).";
    };
  };

  config = lib.mkIf config.dyndns.enable {
    systemd.services.dedyn-update = {
      description = "deSEC DynDNS Update";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        EnvironmentFile = [ config.dyndns.secretTokenPath ];
      };
      script = ''
        IPv4=$(${pkgs.curl}/bin/curl https://checkipv4.dedyn.io/)
        IPv6=$(${pkgs.curl}/bin/curl https://checkipv6.dedyn.io/)
        echo "Current IPv4: $IPv4"
        echo "Current IPv6: $IPv6"
        ${pkgs.curl}/bin/curl --user "${config.dyndns.domain}:$SECRET" "https://update.dedyn.io/?myipv4=$IPv4&myipv6=$IPv6"
      '';
      path = [ pkgs.curl ];
    };

    systemd.timers.dedyn-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "30min";
        Unit = "dedyn-update.service";
      };
    };
  };
}

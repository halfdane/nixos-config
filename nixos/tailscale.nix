# Tailscale NixOS Module
# Provides a reusable, parameterized Tailscale setup with optional agenix secret integration.

{ config, pkgs, lib, ... }:
{
  options.tailscale = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Tailscale service.";
    };
    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to Tailscale auth key file (can reference agenix secret).";
    };
  };

  config = lib.mkIf config.tailscale.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = config.tailscale.authKeyFile;
    };

    # Trust all traffic arriving on the Tailscale interface — no firewall rules
    # needed per service. The public interface stays closed by default.
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    # If tailscale is your network, nothing should need a public port.
    # This catches accidental openFirewall = true or allowedTCPPorts additions.
    assertions = [{
      assertion = config.networking.firewall.allowedTCPPorts == [];
      message = ''
        networking.firewall.allowedTCPPorts is not empty on a tailscale host: ${
          lib.concatStringsSep ", " (map toString config.networking.firewall.allowedTCPPorts)
        }
        All services should be reachable via tailscale only. Remove the port
        or justify it with an explicit allow in the host configuration.
      '';
    }];
  };
}

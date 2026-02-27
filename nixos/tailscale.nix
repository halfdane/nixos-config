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
    allowedPublicTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [];
      description = ''
        Ports intentionally allowed through the public firewall on this tailscale host.
        Each entry must have a comment in the host config explaining why it is justified.
        Example use case: port 22 on a remote VPS for SSH recovery if tailscale fails.
      '';
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
    #
    # To allow a port with justification, add it to tailscale.allowedPublicTCPPorts
    # in the host configuration. E.g. for SSH recovery access on a remote VPS:
    #   tailscale.allowedPublicTCPPorts = [ 22 ]; # SSH: recovery if tailscale fails
    assertions =
      let
        unexpected = lib.subtractLists
          config.tailscale.allowedPublicTCPPorts
          config.networking.firewall.allowedTCPPorts;
        # Best-effort hint: flag known services that open the firewall automatically.
        sshNote = lib.optionalString
          (config.services.openssh.enable && config.services.openssh.openFirewall)
          "\n  (port 22 is opened by services.openssh.openFirewall = true)";
      in [{
        assertion = unexpected == [];
        message = ''
          networking.firewall.allowedTCPPorts contains ports not declared as intentional: ${
            lib.concatStringsSep ", " (map toString unexpected)
          }${sshNote}
          Either remove the port, or declare it intentional in your host config:
            tailscale.allowedPublicTCPPorts = [ <port> ]; # add a comment explaining why
        '';
      }];
  };
}

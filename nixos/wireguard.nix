# WireGuard VPN Server Module
# Provides a reusable hub-and-spoke WireGuard server setup.
# Peers (clients) are declared with a name, public key, and assigned tunnel IP.
# Private keys for NixOS peers should be managed via agenix; phone keys are
# generated ad-hoc using the scripts/wg-add-peer helper.

{ config, lib, pkgs, ... }:

let
  wg-add-peer = pkgs.writeShellApplication {
    name = "wg-add-peer";
    # Dependencies are injected into the script's PATH — no need for them to
    # be in the system PATH or hardcoded as absolute store paths in the script.
    runtimeInputs = [ pkgs.wireguard-tools pkgs.qrencode ];
    text = ''
      export SERVER_HOST="${config.wireguard.endpointHost}"
      # Routing domains tell systemd-resolved (NixOS/curie) and wg-quick to
      # send queries for these domains to the VPN DNS rather than the default
      # system DNS.  The tilde prefix (~) marks them as routing-only domains
      # (not added as search suffixes).  Without this, split-tunnel clients
      # ignore the VPN DNS for external domain names.
      export DNS_ROUTE_DOMAINS="${lib.concatStringsSep ", " (map (d: "~${d}") config.wireguard.dns.domains)}"
      ${builtins.readFile ../scripts/wg-add-peer}
    '';
  };
  wg-scraper = pkgs.writeShellApplication {
    name = "wg-scraper";
    runtimeInputs = [ pkgs.wireguard-tools pkgs.iproute2 ];
    text = ''
      ${builtins.readFile ../scripts/wg-scraper}
    '';
  };
in
{
  options.wireguard = {
    enable = lib.mkEnableOption "WireGuard VPN server";

    serverIp = lib.mkOption {
      type = lib.types.str;
      default = "10.100.0.1";
      description = "Server's IP address within the WireGuard tunnel subnet.";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 51820;
      description = "UDP port WireGuard listens on. Must be open publicly.";
    };

    endpointHost = lib.mkOption {
      type = lib.types.str;
      description = ''
        Public IP address or DNS name that clients should use to reach this
        WireGuard server. Used by the onboarding helper when generating client
        configs.
      '';
    };

    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the server's WireGuard private key (e.g. an agenix secret).";
    };

    peers = lib.mkOption {
      description = "List of authorised WireGuard peers.";
      default = [];
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Human-readable label (not used by WireGuard, just for comments).";
          };
          publicKey = lib.mkOption {
            type = lib.types.str;
            description = "Peer's WireGuard public key (base64).";
          };
          ip = lib.mkOption {
            type = lib.types.str;
            description = "Peer's assigned tunnel IP, e.g. 10.100.0.2";
          };
        };
      });
    };

    dns.domains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Domains (and their subdomains) that VPN clients should resolve to
        the server's tunnel IP. Add every hostname served behind the VPN here
        so that clients can reach services by name rather than by raw IP.
        Example: [ "micasaestu.casa" ]
      '';
    };
  };

  config = lib.mkIf config.wireguard.enable {
    # Allow packets to be forwarded between peers (hub-and-spoke routing).
    boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkDefault 1;

    networking.wireguard.interfaces."wg-server" = {
      ips = [ "${config.wireguard.serverIp}/24" ];
      listenPort = config.wireguard.listenPort;
      privateKeyFile = config.wireguard.privateKeyFile;

      peers = map (peer: {
        publicKey = peer.publicKey;
        # /32 means only traffic explicitly destined for this peer's IP is
        # routed to them — no peer can spoof another peer's address.
        allowedIPs = [ "${peer.ip}/32" ];
      }) config.wireguard.peers;
    };

    # Trust all traffic that has already been cryptographically verified by
    # WireGuard — same pattern as trustedInterfaces for other overlay networks.
    networking.firewall.trustedInterfaces = [ "wg-server" ];

    # WireGuard's only public-facing surface: one UDP port.
    networking.firewall.allowedUDPPorts = [ config.wireguard.listenPort ];

    # DNS for VPN clients: resolve declared domains to the tunnel IP so that
    # clients can reach services by hostname (e.g. music.micasaestu.casa)
    # rather than having to use raw IPs.
    #
    # Architecture: dnsmasq becomes the single DNS resolver on the server,
    # replacing systemd-resolved's stub. It handles two jobs:
    #   1. Authoritative for declared domains → resolves to the tunnel IP
    #   2. Forwards everything else upstream to 1.1.1.1 / 8.8.8.8
    #
    # This avoids the split-brain that occurs when dnsmasq only binds to the
    # WireGuard interface while systemd-resolved points at 127.0.0.1:53.
    services.resolved.settings = lib.mkIf (config.wireguard.dns.domains != []) {
      Resolve.DNSStubListener = "no";
    };

    services.dnsmasq = lib.mkIf (config.wireguard.dns.domains != []) {
      enable = true;
      settings = {
        # Forward unknown queries upstream — required now that dnsmasq owns
        # port 53 globally instead of only on the WireGuard interface.
        server = [ "1.1.1.1" "8.8.8.8" ];
        # Resolve each declared domain and all its subdomains to the server.
        address = map (domain: "/${domain}/${config.wireguard.serverIp}")
          config.wireguard.dns.domains;
      };
    };

    # prometheus metrics exporter service + timer
    systemd.services.wireguard-metrics = {
      script = ''
        set -eu
        ${wg-scraper}/bin/wg-scraper
      '';
      description = "WireGuard Prometheus metrics collector";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      startAt = "*:*:0/30";
    };

    # Install the peer-onboarding helper on the server.
    environment.systemPackages = [ wg-add-peer wg-scraper ];
  };
}

# Shared networking defaults for NetworkManager-based hosts.
#
# Enables systemd-resolved as the DNS backend so that per-connection routing
# domains (e.g. ~micasaestu.casa on a WireGuard interface) are respected.
# Without this, resolvconf merges all DNS servers globally and a VPN DNS server
# takes over all resolution when a tunnel is up — causing total DNS failure if
# the tunnel becomes unstable.
{ ... }:
{
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
}

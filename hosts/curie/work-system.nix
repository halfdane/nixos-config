{ config, pkgs, lib, inputs, ... }:

let
  # CA certs come from minerva_owl-setup when cloned (same bootstrap timing as other OSes).
  # Requires --impure (see Taskfile.yml); absent before `task repos:clone`, active after.
  minervaPath = "/home/user/work/minerva/minerva_owl-setup";

  gateway = "byod.gp.ottogroup.com";
  gpoc = inputs.globalprotect-openconnect.packages.${pkgs.system}.fromSource;

  vpn-connect = pkgs.writeShellScriptBin "vpn-connect" ''
    set -euo pipefail
    echo "Starting SAML login via default browser..."

    # Flush the IPv6 black-hole route that the tunnel installs on tun0;
    # otherwise dual-stack corporate hosts hang (browser tries IPv6 first).
    (
      for _ in $(seq 1 30); do
        if ${pkgs.iproute2}/bin/ip link show tun0 >/dev/null 2>&1; then
          sudo ${pkgs.iproute2}/bin/ip -6 route flush dev tun0 2>/dev/null || true
          break
        fi
        sleep 1
      done
    ) &

    ${gpoc}/bin/gpauth ${gateway} --gateway --browser \
      | sudo ${gpoc}/bin/gpclient connect ${gateway} \
          --as-gateway --cookie-on-stdin --hip --disable-ipv6 "$@"
  '';

  vpn-disconnect = pkgs.writeShellScriptBin "vpn-disconnect" ''
    sudo ${gpoc}/bin/gpclient disconnect "$@"
  '';
in
{
  imports = if builtins.pathExists "${minervaPath}/nixos/default.nix"
    then [ (import "${minervaPath}/nixos/default.nix") ]
    else [];

  # Prefer IPv4 for dual-stack hosts while VPN is active (the tunnel is IPv4-only
  # but installs a black-hole IPv6 default route; this makes glibc pick IPv4).
  environment.etc."gai.conf".text = ''
    label  ::1/128       0
    label  ::/0          1
    label  2002::/16     2
    label  ::/96         3
    label  ::ffff:0:0/96 4
    precedence  ::1/128       50
    precedence  ::/0          40
    precedence  2002::/16     30
    precedence  ::/96         20
    precedence  ::ffff:0:0/96 100
  '';

  environment.systemPackages = [ gpoc vpn-connect vpn-disconnect ];
}

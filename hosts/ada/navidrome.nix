{ config, pkgs, lib, ... }:
{

  services.navidrome = {
    enable = true;
    # openFirewall is intentionally omitted — tailscale0 is a trusted interface
    # (see nixos/tailscale.nix), so navidrome is reachable over tailnet without
    # opening any public ports.
    settings = {
      MusicFolder = "/data/Music";
      Address = "0.0.0.0";
    };
  };


}
{ config, pkgs, lib, nixpkgsNavidrome, ... }:
{
  services.navidrome = {
    enable = true;
    package = nixpkgsNavidrome.navidrome;
    # openFirewall is intentionally omitted — wg0 is a trusted interface
    # (see nixos/wireguard.nix), so navidrome is reachable over the WireGuard
    # tunnel without opening any public ports.
    group = "music";
    settings = {
      MusicFolder = "/data/Music";
      Address = "127.0.0.1";
      ND_DEFAULTPLAYLISTPUBLICVISIBILITY = true;
    };
  };

  services.nginx.virtualHosts."music.micasaestu.casa" = {
    useACMEHost = "micasaestu.casa";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:4533";
      proxyWebsockets = true;
    };
  };

}
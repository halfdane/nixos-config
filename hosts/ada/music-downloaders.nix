{ config, pkgs, lib, ... }: {
  virtualisation = {
    podman.enable = true;
    oci-containers.backend = "podman";
  };

  virtualisation.oci-containers.containers = {
    tidarr = {
      image = "cstaelen/tidarr:latest";
      autoStart = true;
      ports = ["8484:8484"];
      volumes = ["/var/lib/tidarr:/shared" "/data/Music:/music"];
      environment = {
        PUID = "1000";  # uid=1000(halfdane)
        PGID = "998";   # gid=998(halfdane)
        TZ = "Europe/Berlin";
      };
    };

    downtify = {
      image = "ghcr.io/henriquesebastiao/downtify:latest";
      autoStart = true;
      ports = ["3000:8000"];
      volumes = ["/var/lib/downtify:/data" "/data/Music:/downloads"];
      environment = {
        PUID = "1000";
        PGID = "998";
        TZ = "Europe/Berlin";
        CLIENT_ID="771e74504fe14081844bd38ec410bde8";
        CLIENT_SECRET="b570073890534c9abf0e637c91f111aa";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [8484 3000];

  systemd.tmpfiles.rules = [
    "Z /data/Music 0755 halfdane halfdane - -"
    "Z /var/lib/tidarr 0755 halfdane halfdane - -"
    "Z /var/lib/downtify 0755 halfdane halfdane - -"

    "d /var/lib/tidarr 0755 halfdane halfdane - -"
    "d /var/lib/downtify 0755 halfdane halfdane - -"
    "d /data/Music 0755 halfdane halfdane - -"
  ];
}

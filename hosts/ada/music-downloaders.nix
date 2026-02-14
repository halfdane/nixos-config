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

    # Downtify is currently broken 
    # downtify = {
    #   image = "ghcr.io/henriquesebastiao/downtify:latest";
    #   autoStart = true;
    #   ports = ["3000:8000"];
    #   volumes = ["/var/lib/downtify:/data" "/data/Music:/downloads"];
    #   environment = {
    #     PUID = "1000";
    #     PGID = "998";
    #     TZ = "Europe/Berlin";
    #   };
    # };

    # Zotify Backend (Spotify Premium CLI)
    # zotify-backend = {
    #   image = "xasiklas/zotifybackend:latest";
    #   autoStart = true;
    #   ports = ["1337:1337"];
    #   volumes = [
    #     "/var/lib/zotify:/config"
    #     "/data/Music:/media"
    #   ];
    #   environment = {
    #     PUID = "1000";
    #     PGID = "998";
    #     TZ = "Europe/Berlin";
    #     # Spotify Premium creds (secrets later)
    #   };
    # };

    # # Zotify Frontend (Web UI)
    # zotify-frontend = {
    #   image = "xasiklas/zotifyfrontend:latest";
    #   autoStart = true;
    #   ports = ["5173:5173"];
    #   environment = {
    #     BACKEND_URL = "http://host.docker.internal:1337";  # Points to backend
    #   };
    #   dependsOn = [ "zotify-backend" ];
    # };

  };

  networking.firewall.allowedTCPPorts = [8484 3000 1337 5173];

  systemd.tmpfiles.rules = [
    "d /var/lib/tidarr 0755 halfdane halfdane - -"
    "d /var/lib/downtify 0755 halfdane halfdane - -"
    "d /var/lib/zotify 0755 halfdane halfdane - -"
    "d /data/Music 0755 halfdane halfdane - -"
  ];
}

{ config, lib, pkgs, ... }:
{
  age.secrets = {
    tailscale-invite.file = ./../../secrets/tailscale-invite.age;
  };
  imports = [
    ./hardware-configuration-ada.nix
    ./disko.nix
    ./navidrome.nix
    ./acme.nix
    ./world_readable_music.nix
  ];

  # Use the reusable Tailscale module
  tailscale = {
    enable = true;
    authKeyFile = config.age.secrets.tailscale-invite.path;
    # SSH is intentionally reachable on the public internet as a recovery path:
    # if tailscale fails on this remote VPS, SSH is the only way back in without
    # using the netcup rescue console. Mitigated by key-only auth, no root login.
    allowedPublicTCPPorts = [ 22 ];
  };

  music = {
    dir = "/data/Music";
    group = "music";
    members = [ "navidrome" "fetching" ];
  };
  
  boot.initrd.luks.devices."luks-root".fallbackToPassword = true;
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Basic networking (systemd-networkd, ens3 DHCP)
  networking.hostName = "ada";
  networking.useDHCP = false;
  systemd.network.enable = true;
  networking.interfaces.ens3.useDHCP = true;

  users.groups.halfdane = {};
  users.users.halfdane = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    group = "halfdane";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK10b+CmOMZsc4cLe7CmbSmibCIGA7KC3yY447e1qxtS tvollert@nixos"
    ];
  };

  # Enable sudo without pw
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Enable SSH (for remote access)
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };

  nix.settings = {
    require-sigs = false;
    substituters = [
      "https://halfdane-fetching.cachix.org"
      "https://halfdane-prometheus-renderer.cachix.org"
    ];
    trusted-public-keys = [
      "halfdane-fetching.cachix.org-1:47X7VUX6TAyHWa8IcE2a3wY9L4KGQUnScTGvrjE8Bvs="
      "halfdane-prometheus-renderer.cachix.org-1:zm3ooc8nwjZZBJORT5ku5cZIppQzrnL7gCOdLQyW2qI="
    ];
  };

  # Timezone
  time.timeZone = "Europe/Berlin";

  services.fetching.enable = true;

  services.nginx.virtualHosts."fetching.micasaestu.casa" = {
    useACMEHost = "micasaestu.casa";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9733";
      proxyWebsockets = true;
    };
  };

  services.ilias = {
    enable = true;
    configDir = ./ilias;

    extraPackages = [ pkgs.openssl ];

    nginx = {
      enable = true;
      hostName = "micasaestu.casa";
      forceSSL = true;
      acmeHost = "micasaestu.casa";
    };
  };

  services.prometheus = {
    enable = true;
    scrapeConfigs = [{
      job_name = "node";
      static_configs = [{ targets = ["localhost:9100"]; }];
    }];
    exporters.node = {
      enable = true;
      extraFlags = [ "--collector.textfile.directory=/var/lib/node_exporter/textfile_collector" ];
    };

  };
  programs.prometheus-renderer.enable = true;

  # report deployment changes to node exporter
  system.activationScripts.writeSystemVersion = {
    text = ''
      mkdir -p /var/lib/node_exporter/textfile_collector
      echo "nixos_system_version{version=\"$(readlink -f /run/current-system | xargs basename)\"} 1" \
        > /var/lib/node_exporter/textfile_collector/nixos_system_version.prom
    '';
  };
}

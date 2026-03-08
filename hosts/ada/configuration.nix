{ config, lib, pkgs, ... }:
{
  age.secrets = {
    wg-server.file = ./../../secrets/wg-server.age;
  };
  imports = [
    ./hardware-configuration-ada.nix
    ./disko.nix
    ./navidrome.nix
    ./acme.nix
    ./fix_data_dir.nix
    ./prometheus.nix
  ];


  music = {
    dir = "/data";
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

  # Enable SSH — accessible only through the WireGuard tunnel (wg0 is a
  # trusted interface, so no explicit port needed). Not exposed publicly.
  # Recovery path if WireGuard config breaks: 
  # - netcup KVM rescue console and:
  #   sudo nix-env -p /nix/var/nix/profiles/system --rollback
  #   sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
  services.openssh = {
    enable = true;
    openFirewall = false;
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

  wireguard = {
    enable = true;
    endpointHost = "152.53.176.47";
    privateKeyFile = config.age.secrets.wg-server.path;
    dns.domains = [ "micasaestu.casa" ];
    peers = [
      # Add peers here after running scripts/wg-add-peer to generate their keys.
      { name = "curie"; publicKey = "qMIIXDuMy813aF/fvHs7jW8TyDqunlPtkk29zCWwKnI="; ip = "10.100.0.2"; }
      { name = "halfdane_phone"; publicKey = "d+pnZufuTJrUgNV3ssmqYGwmtlv2F2JwWBRa2Jh2tWs="; ip = "10.100.0.3"; }
      { name = "tv_fritzbox"; publicKey = "dsmmCyBb+3By4OC4MHQOPiL/z0nOp5SnN85h8wR1Cz8="; ip = "10.100.0.4"; }
    ];
  };

  services.fetching = {
    enable = true;
    port = 9733;
    outputDir = "/data/Music";
    trackTemplate = "{artist}/{year}-{album}/{track_number}-{title}";
    nginx = {
      enable = true;
      hostName = "fetching.micasaestu.casa";
      forceSSL = true;
      acmeHost = "micasaestu.casa";
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

  prometheus = {
    enable = true;
    node-exporter-btrfs.enable = true;
    node-exporter-btrfs.directoriesToReport = [ "/data" ];
  };

  programs.prometheus-renderer.enable = true;

    # Hourly Snapper on /home (prunes aggressively)
  services.snapper.configs.home = {
    SUBVOLUME = "/home";
    FSTYPE = "btrfs";
    ALLOW_USERS = [ "halfdane" ];  # Replace
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_MIN_AGE = "1800";
    TIMELINE_LIMIT_HOURLY = "5";
    TIMELINE_LIMIT_DAILY = "7";
    TIMELINE_LIMIT_WEEKLY = "4";
    TIMELINE_LIMIT_MONTHLY = "3";
  };


}

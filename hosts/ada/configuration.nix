{ config, lib, pkgs, ... }:
{
  age.secrets = {
    wg-server.file = ./../../secrets/wg-server.age;
    privado-wg.file = ./../../secrets/privado-wg.age;
  };
  imports = [
    ./hardware-configuration-ada.nix
    ./disko.nix
    ./navidrome.nix
    ./jellyfin.nix
    ./arr_stack.nix
    ./acme.nix
    ./fix_data_dir.nix
    ./prometheus.nix
    ./usenet_vpn.nix
  ];

  music.dir = "/data";
  
  boot.initrd.luks.devices."luks-root".fallbackToPassword = true;

  # Basic networking (systemd-networkd, ens3 DHCP)
  networking.hostName = "ada";
  networking.useDHCP = false;
  systemd.network.enable = true;
  networking.interfaces.ens3.useDHCP = true;

  users.groups.halfdane = {};
  users.users.halfdane = {
    isNormalUser = true;
    extraGroups = [ "wheel" "music" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ config.my.sshPubKeys.personal ];
  };

  # Enable SSH — accessible only through the WireGuard tunnel (wg0 is a
  # trusted interface, so no explicit port needed). Not exposed publicly.
  # Recovery path if WireGuard config breaks: 
  # - netcup KVM rescue console and:
  #   sudo nix-env -p /nix/var/nix/profiles/system --rollback
  #   sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
  services.openssh.enable = true;

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

  usenet = {
    enable = true;
    privateKeyFile = config.age.secrets.privado-wg.path;
  };

  services.fetching = {
    enable = true;
    port = 9733;
    outputDir = "/data/Music";
    trackTemplate = "{artist}/{year}-{album}/{track_number}-{title}";
    user = "fetching";
    group = "music";
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

  # default route for random subdomains: just refuse connection
  services.nginx = {
    enable = true;
    virtualHosts.default = {
      serverName = "_";
      default = true;
      rejectSSL = true;
      locations."/".return = "444";
    };
  };
}

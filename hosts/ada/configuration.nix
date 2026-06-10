{ config, pkgs, lib, inputs, username, hostname, ... }:
{
  age.secrets = {
    wg-server.file = ./../../secrets/wg-server.age;
    privado_config.file = ./../../secrets/privado_config.age;
    eweka.file = ./../../secrets/eweka.age;
    hetzner_storage.file = ./../../secrets/hetzner_storage.age;
  };
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./navidrome.nix
    ./nixarr.nix
    ./acme.nix
    ./prometheus.nix
    ./paperless.nix
  ];
  
  boot.initrd.availableKernelModules = [ "virtio_scsi" "virtio_blk" "virtio_pci" "ata_piix" ];
  boot.initrd.kernelModules = [ "dm-crypt" "cryptd" ];

  # Basic networking (systemd-networkd, ens3 DHCP)
  networking.hostName = hostname;
  networking.useDHCP = false;
  systemd.network.enable = true;
  networking.interfaces.ens3.useDHCP = true;

  users.groups.${username} = {};
  users.users.${username} = {
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
  networking.firewall.allowedTCPPorts = [ 22 ];

  wireguard = {
    enable = true;
    endpointHost = "152.53.176.47";
    privateKeyFile = config.age.secrets.wg-server.path;
    dns.domains = [ "micasaestu.casa" ];
    peers = [
      # Add peers here after running scripts/wg-add-peer to generate their keys.
      { name = "halfdane_phone"; publicKey = "d+pnZufuTJrUgNV3ssmqYGwmtlv2F2JwWBRa2Jh2tWs="; ip = "10.100.0.3"; }
      { name = "tv_fritzbox"; publicKey = "dsmmCyBb+3By4OC4MHQOPiL/z0nOp5SnN85h8wR1Cz8="; ip = "10.100.0.4"; }
      { name = "curie"; publicKey = "5Fj83zAxSWewFghe2VuoM7Nd++cFRUNyKcuPmoJZflY="; ip = "10.100.0.5"; }
    ];
  };

  nixarr = {
    enable = true;
    wgConfigPath = config.age.secrets.privado_config.path;
  };

  services.fetching = {
    enable = true;
    port = 9733;
    outputDir = "/mnt/storagebox/media/fetching";
    trackTemplate = "{artist}/{year}-{album}/{track_number}-{title}";
    user = "fetching";
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

  prometheus.enable = true;
  programs.prometheus-renderer.enable = true;

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

  services.nginx.virtualHosts."timer.micasaestu.casa" = {
    useACMEHost = "micasaestu.casa";
    forceSSL = true;
    root = pkgs.fetchFromGitHub {
      owner = "halfdane";
      repo = "prog_timer";
      rev = "1d9f39bb90382590b03e1e452516836906e0bc1a";
      hash = "sha256-j9pPmZJ/bkzqvjHLpTRH6GpEg/aNpdWqgrJ3vYWf08Y=";
    };
    locations."/" = {
      index = "progressive-timer.html";
    };
  };

  services.storagebox = {
    enable = true;
    mountpoint = "/mnt/storagebox";
    sshKeyPath = config.age.secrets.hetzner_storage.path;
    server     = "u564954.your-storagebox.de";
    username   = "u564954";
  };

  services.paperless.enable = true;

}

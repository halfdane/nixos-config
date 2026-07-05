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
  
  services.qemuGuest.enable = true;

  boot.initrd.availableKernelModules = [ "virtio_scsi" "virtio_blk" "virtio_pci" "ata_piix" ];
  boot.initrd.kernelModules = [ "dm-crypt" "cryptd" ];

  # Auto-unlock the root LUKS volume with a keyfile so no passphrase prompt is
  # needed at boot. The keyfile is generated on ada at
  # /etc/secrets/initrd/crypto_keyfile.bin and baked into the initrd at
  # activation time. The initrd lives on the unencrypted /boot.
  #
  # SECURITY TRADE-OFF: this effectively removes at-rest protection against
  # anyone who can read the boot disk (including the VPS provider), since the
  # key sits in cleartext inside the initrd on /boot. Accepted deliberately in
  # exchange for unattended reboots.
  #
  # fallbackToPassword is implicit with the systemd-stage-1 initrd used here:
  # systemd-cryptsetup automatically prompts for the passphrase if the keyfile
  # is missing or doesn't match, so this config is safe to deploy *before* the
  # matching LUKS keyslot has been added.
  boot.initrd.secrets."/crypto_keyfile.bin" = "/etc/secrets/initrd/crypto_keyfile.bin";
  boot.initrd.luks.devices."luks-root" = {
    keyFile = "/crypto_keyfile.bin";
  };

  # Auto-reboot instead of hanging on kernel faults. This is a headless netcup
  # VPS: by default `kernel.panic=0` halts forever, so a panic requires a
  # manual console reset. Set as kernel params so they apply from the very
  # first instant of boot (earlier than sysctls would). Now that the disk
  # auto-unlocks, an unattended reboot brings the box straight back up.
  boot.kernelParams = [
    "panic=10"           # reboot 10s after a kernel panic
    "oops=panic"         # promote a kernel oops to a full panic -> reboot
    "softlockup_panic=1" # a CPU soft-lockup triggers a panic -> reboot
  ];

  # Persist logs across reboots so the crash that triggers an auto-reboot can
  # actually be diagnosed afterwards (journald otherwise keeps them only in
  # volatile /run and loses them on the following reboot).
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=500M
  '';

  # Proactively kill the worst memory hog under pressure instead of letting the
  # box thrash into a soft-lockup/hang. systemd-oomd is enabled by default but
  # only manages user slices; the services here (jellyfin, sabnzbd, paperless,
  # the *arr stack) all run under system.slice, so extend oomd to act on swap
  # pressure there too. This is the userspace safety net that should stop the
  # crashes at the source; the panic=/oops= reboot params are the last resort.
  systemd.oomd.enableSystemSlice = true;

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

  # Enable SSH — accessible only through the WireGuard tunnel (wg-server is a
  # trusted interface, so no explicit firewall port is opened). Deliberately
  # NOT exposed on the public interface.
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
    # Services that read from / write to the mount. Ordered after the rclone
    # mount so downloads never land on the local disk before it is live.
    dependentServices = [
      "sonarr" "radarr" "lidarr" "bazarr" "jellyfin"
      "sabnzbd" "navidrome" "fetching"
    ];
  };

  services.paperless.enable = true;

}

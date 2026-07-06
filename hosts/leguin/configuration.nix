{ config, pkgs, lib, inputs, username, hostname, ... }:
{
  age.secrets = {
    user-ssh-key = {
      file = ./../../secrets/personal_ssh.age;
      path = "/run/agenix/user-ssh-key";
      owner = "${username}";
      mode = "600";
    };
    hetzner_storage.file = ./../../secrets/hetzner_storage.age;
  };

  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];
  services.maestral = {
    enable = true;
    user = "${username}";
  };
  services.kde = {
    enable = true;
    autoLogin = "${username}";
  };
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  # despite using en_us, I still want German locale settings for things like date formatting, measurement units, etc.
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ config.my.sshPubKeys.personal ];
  };

  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  
  environment.systemPackages = with pkgs; [
    bindfs
    file
    jellyfin-desktop
  ];

  hardware.bluetooth = {
    enable = true; # Aktiviert den Bluetooth-Dienst
    powerOnBoot = true; # Schaltet Bluetooth beim Systemstart ein
  };

  # allow kde connect
  networking.firewall = {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };

  services.storagebox = {
    enable = true;
    mountpoint = "/mnt/storagebox";
    sshKeyPath = config.age.secrets.hetzner_storage.path;
    server     = "u564954.your-storagebox.de";
    username   = "u564954";
    # Wait for the mount before Jellyfin scans, so it never indexes an empty
    # directory skeleton on boot.
    dependentServices = [ "jellyfin" ];
  };

  # Local Jellyfin server: reads the same Storage Box mount directly and is
  # played back by jellyfin-desktop over localhost. This bypasses ada's
  # middle hop and its overloaded CPU/RAM entirely — the only WAN leg left is
  # Hetzner -> leguin. openFirewall opens the standard Jellyfin ports (8096/
  # 8920 TCP + 1900/7359 UDP discovery) so other trusted home-LAN devices can
  # reach it as http://leguin:8096 as well as the local desktop client.
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

}

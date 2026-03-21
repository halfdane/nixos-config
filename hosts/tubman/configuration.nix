# Laptop host configuration
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./arr_stack.nix
    ./prometheus.nix
    ./dyndns.nix
  ];
  hardware.enableRedistributableFirmware = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tubman";
  networking.networkmanager.enable = true;
  networking.wireless.enable = true;
  programs.nm-applet.enable = true;

  age.secrets = {
    user-ssh-key = {
      file = ./../../secrets/personal_ssh.age;
      path = "/run/agenix/user-ssh-key";
      owner = "${username}";
      mode = "600";
    };
    "privado_config.conf" = {
      file = ./../../secrets/privado_config.age;
      path = "/run/agenix/privado_config.conf";
      owner = "${username}";
      mode = "600";
    };
    wg-server = {
      file = ./../../secrets/wg-server.age;
      path = "/run/agenix/wg-server";
      owner = "${username}";
      mode = "600";
    };
    dyndns.file = ./../../secrets/dyndns.age;
  };
  services.maestral = {
    enable = true;
    user = "${username}";
  };
  services.kde = {
    enable = true;
    autoLogin = "${username}";
  };
  programs.nix-ld.enable = true;

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
    extraGroups = [ "networkmanager" "wheel" "docker" "media" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ config.my.sshPubKeys.personal ];
  };

  virtualisation.docker.enable = true;
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  environment.systemPackages = with pkgs; [
    bindfs
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gstreamer
    file
    ffmpeg
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

  arr = {
    enable = true;
    password = config.age.secrets.eweka;
  };

  dyndns = {
    enable = true;
    secretTokenPath = config.age.secrets.dyndns.path;
    domain = "micasaestu.dedyn.io";
  };

  services.ilias = {
    enable = true;
    configDir = ./ilias;
    extraPackages = [ pkgs.openssl ];
  };

  services.prometheus.enable = true;
  programs.prometheus-renderer.enable = true;
    services.nginx.virtualHosts."prometheus.tubman" = {
      serverName = "prometheus.tubman";
      locations."/" = {
        proxyPass = "http://127.0.0.1:9090";
        proxyWebsockets = true;
      };
    };

  services.nginx.virtualHosts."tubman" = {
    serverName = "_";
    default = true;
    root = builtins.dirOf config.services.ilias.outputPath;
    locations."/" = {
      index = builtins.baseNameOf config.services.ilias.outputPath;
    };
  };

  
  wireguard = {
    enable = true;
    endpointHost = "94.134.111.167";
    privateKeyFile = config.age.secrets.wg-server.path;
    dns.domains = [ "micasaestu.dedyn.io" ];
    peers = [
      # Add peers here after running scripts/wg-add-peer to generate their keys.
      { name = "halfdane_phone"; publicKey = "C00UYrkTcB8bsAbdgG0Gx+N0FzXvBBjhAQBduMqRzzQ="; ip = "10.100.0.6"; }
      { name = "curie"; publicKey = "pg6gxLgNG1Kmq5VqzYlRaL+VSost7Wfx4to/IepaLjg="; ip = "10.100.0.6"; }
    ];
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      listen-address = [ "127.0.0.1" "192.168.178.145" ];
      address = [ "/tubman/192.168.178.145" ];

      server = [ "8.8.8.8" "8.8.4.4" "94.140.14.14" "94.140.15.15" ];
      no-hosts = true;
    };
  };

}

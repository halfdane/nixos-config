# Laptop host configuration
{ config, pkgs, lib, inputs, username, ... }:
{
  nixpkgs.overlays = [ inputs.nixos-aarch64-widevine.overlays.default ];
  imports = [
    ./hardware-configuration.nix
    ./qemu-vm.nix
    ./work-system.nix
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
  programs.nix-ld.enable = true;

  # Enable x86_64 emulation on aarch64
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "curie";
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
    extraGroups = [ "networkmanager" "wheel" "docker" "media" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ config.my.sshPubKeys.personal ];
  };

  virtualisation.docker.enable = true;
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  
  environment.sessionVariables.MOZ_GMP_PATH = [ "${pkgs.widevine-cdm-lacros}/gmp-widevinecdm/system-installed" ];
  environment.systemPackages = with pkgs; [
    bindfs
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gstreamer
    kid3
    file
    strawberry
    ffmpeg
    jetbrains.idea
  ];
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
    };
  };

  hardware.bluetooth = {
    enable = true; # Aktiviert den Bluetooth-Dienst
    powerOnBoot = true; # Schaltet Bluetooth beim Systemstart ein
  };

  # allow kde connect
  networking.firewall = {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };

  # Media group for perms
users.groups.media = { };

  systemd.tmpfiles.rules = [
    # Top-level /data: 2775 root:media (new files/subdirs inherit media group)
    "d /data 2775 root media - -"

    # Usenet flow
    "d /data/usenet 2775 root media - -"
    "d /data/usenet/incomplete 2775 root media - -"
    "d /data/usenet/complete 2775 root media - -"
    "d /data/usenet/complete/movies 2775 root media - -"
    "d /data/usenet/complete/tv 2775 root media - -"
    "d /data/usenet/complete/music 2775 root media - -"

    # Media libraries (Jellyfin/Navidrome scan)
    "d /data/media 2775 root media - -"
    "d /data/media/Movies 2775 root media - -"
    "d /data/media/TV 2775 root media - -"
    "d /data/media/Music 2775 root media - -"

    # Music manual/beets
    "d /data/music-incoming 2775 root media - -"
    "d /data/music-library 2775 root media - -"

    # Configs (separate, tighter perms)
    "d /data/arr/config 2775 root media - -"
    "d /data/arr/config/radarr 2775 root media - -"
    "d /data/arr/config/sonarr 2775 root media - -"
    "d /data/arr/config/lidarr 2775 root media - -"
    "d /data/arr/config/prowlarr 2775 root media - -"
    "d /data/arr/config/nzbget 2775 root media - -"
  ];
  
  age.secrets.user-ssh-key = {
    file = ./../../secrets/personal_ssh.age;
    path = "/run/agenix/user-ssh-key";
    owner = "${username}";
    mode = "600";
  };

}

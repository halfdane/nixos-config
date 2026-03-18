# Laptop host configuration
{ config, pkgs, lib, inputs, ... }:

let
  userConfig = import ./user-config.nix;
in
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
    user = "${userConfig.username}";
  };
  services.kde = {
    enable = true;
    autoLogin = "${userConfig.username}";
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

  users.users.${userConfig.username} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "docker" "media" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ config.my.sshPubKeys.personal ];
  };

  virtualisation.docker.enable = true;
  
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
    "d /data 2775 root media - -"
  ];

}

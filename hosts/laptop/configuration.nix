# Laptop host configuration
{ config, pkgs, lib, inputs, ... }:

let
  userConfig = import ./user-config.nix;
in
{
  agenix.secrets = {
    "secrets/laptop-test.age" = ../../secrets/laptop-test.age;
    "secrets/tailscale-invite.age" = ../../secrets/tailscale-invite.age;
  };
  nixpkgs.overlays = [ inputs.nixos-aarch64-widevine.overlays.default ];
  imports = [
    ./hardware-configuration-laptop.nix
    ./qemu-vm.nix
    ./work-system.nix
  ];

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];


  # Enable x86_64 emulation on aarch64
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
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

  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
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
    description = userConfig.fullName;
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
  };

  security.sudo = {
    enable = true;
    # Sudo no pw
    wheelNeedsPassword = false;
  };

  virtualisation.docker.enable = true;
  programs.fish.enable = true;
  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;
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
    vorbis-tools
  ];
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
    };
  };

  networking.firewall = {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };
}

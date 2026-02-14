{ config, lib, pkgs, ... }:
{
  age.secrets = {
    "tailscale-invite.age".file = ./../../secrets/tailscale-invite.age;
  };
  imports = [
    ./hardware-configuration-ada.nix
    ./disko.nix
    ./navidrome.nix
    ./homer
    ./music-downloaders.nix
  ];
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

  users.users.root = {
    hashedPassword = "!";  # Locked
  };

  # Enable sudo without pw
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Minimal packages
  environment.systemPackages = with pkgs; [
    # Is globally enabled in common
    # keeping it here as example of how to enable programs host-specific
    # vim
  ];

  # Enable SSH (for remote access)
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };

  nix.settings.require-sigs = false;

  # Timezone
  time.timeZone = "Europe/Berlin";
}

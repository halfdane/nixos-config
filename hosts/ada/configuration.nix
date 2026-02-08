# Minimal NixOS configuration for ada (VPS)
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration-ada.nix
    ];

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

  # Enable sudo
  security.sudo = {
    enable = true;
    # Sudo no pw
    wheelNeedsPassword = false;
  };

  # Minimal packages
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  # Enable SSH (for remote access)
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };


  # Timezone
  time.timeZone = "Europe/Berlin";

  system.stateVersion = "25.11";
}

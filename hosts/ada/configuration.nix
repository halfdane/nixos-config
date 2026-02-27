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
    ./acme.nix
  ];

  # Use the reusable Tailscale module
  tailscale = {
    enable = true;
    authKeyFile = config.age.secrets."tailscale-invite.age".path;
    # SSH is intentionally reachable on the public internet as a recovery path:
    # if tailscale fails on this remote VPS, SSH is the only way back in without
    # using the netcup rescue console. Mitigated by key-only auth, no root login.
    allowedPublicTCPPorts = [ 22 ];
  };
  
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

  # Enable sudo without pw
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Enable SSH (for remote access)
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };

  nix.settings.require-sigs = false;

  # Timezone
  time.timeZone = "Europe/Berlin";

  services.fetching.enable = true;
}

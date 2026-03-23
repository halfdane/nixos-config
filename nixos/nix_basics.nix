{ config, pkgs, lib, agenix, ... }:

{
  # host key is usually a safe bet for decrypting secrets
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  environment.systemPackages = with pkgs; [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    bashInteractive
    jq
    curl
    wget
    direnv
    vim
    screen
    watchexec
    wireguard-tools
    tree
    go-task
    dig
    htop
  ];

  environment.variables.EDITOR = "vim";
  programs.fish.enable = true;

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

  systemd.network.wait-online.enable = false;

  # Lock the root account on all hosts. There is no legitimate reason to log
  # in as root directly — use sudo from a wheel user instead.
  users.users.root.hashedPassword = lib.mkDefault "!";
  # Timezone
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # in case anyone enables ssh, the default config is 
  # to allow only key-based auth and prohibit root login
  services.openssh = {
    openFirewall = false;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };

  # Enable sudo without pw
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  nix.settings.trusted-users = [ "@wheel" ];

  # let oom killer become active earlier: before the whole machine crashes and burns!
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 3;  # Kill at 3% RAM
    freeSwapThreshold = 10;
    extraArgs = [ "-g" ];  # GPU ignore if any
  };


  # Safety net: rootful podman/docker bypass the NixOS firewall via iptables
  # DNAT. Port bindings must always include an explicit host IP to avoid
  # binding to 0.0.0.0 and becoming publicly reachable.
  # Bare "host:container" format (e.g. "8484:8484") is never correct on a
  # server — use "<ip>:8484:8484" instead.
  assertions =
    let
      # --- Container port safety ---
      allPorts = lib.concatLists (
        lib.mapAttrsToList (_: c: c.ports or [])
          config.virtualisation.oci-containers.containers
      );
      unsafePorts = lib.filter
        (p: lib.length (lib.splitString ":" p) < 3)
        allPorts;

      # --- SSH hardening ---
      sshEnabled = config.services.openssh.enable;
      sshCfg = config.services.openssh.settings;
    in [
      # Rootful containers bypass the NixOS firewall via iptables DNAT.
      # Bare "8484:8484" binds to 0.0.0.0; always use "<ip>:8484:8484".
      {
        assertion = unsafePorts == [];
        message = ''
          Unsafe container port bindings detected — these bypass the firewall and expose ports publicly:
            ${lib.concatStringsSep "\n  " unsafePorts}
          Always bind to an explicit IP, e.g. "100.90.76.7:8484:8484" instead of "8484:8484".
        '';
      }

      # SSH password auth allows brute-force attacks from the internet.
      {
        assertion = !sshEnabled || sshCfg.PasswordAuthentication == false;
        message = "SSH password authentication must be disabled. Set services.openssh.settings.PasswordAuthentication = false.";
      }

      # Root login via SSH is almost never justified.
      {
        assertion = !sshEnabled || sshCfg.PermitRootLogin != "yes";
        message = "SSH root login is set to 'yes'. Use 'no' or 'prohibit-password' instead.";
      }
    ];

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.11";
}

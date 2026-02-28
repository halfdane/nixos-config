{ config, pkgs, lib, agenix, ... }:

{
  environment.systemPackages = with pkgs; [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    jq
    curl
    wget
    direnv
    vim
    screen
    watchexec
  ];

  environment.variables.EDITOR = "vim";

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

  system.stateVersion = "25.11";
}

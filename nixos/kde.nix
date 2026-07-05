{ config, lib, pkgs, username, ... }:

let
  cfg = config.services.kde;
in {
  options.services.kde = {
    enable = lib.mkEnableOption "KDE Plasma6 desktop with SDDM";
    autoLogin = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Username for auto-login (empty = disabled)";
      example = "halfdane";
    };
    secretService = lib.mkOption {
      type = lib.types.enum [ "gnome-keyring" "oo7" ];
      default = "gnome-keyring";
      description = ''
        Which Secret Service (org.freedesktop.secrets) provider to use.

        - "gnome-keyring": stable, desktop-agnostic default.
        - "oo7": EXPERIMENTAL Rust provider. Password prompts are rendered
          natively by Plasma's ksecretprompter (shipped in plasma-workspace
          6.6+). See
          https://planet.kde.org/marco-martin-2026-01-30-kwallet-secretservice-oo7-the-story-so-far/

          Caveat: this only wires up the oo7 daemon (DBus-activated on the
          org.freedesktop.secrets name). Plasma's own ksecretd/kwallet also
          claims that name, so for oo7 to actually take over you must disable
          ksecretd per-user via ~/.config/kwalletrc (one-time, migrates data):

            [Migration]
            MigrateTo3rdParty=true
            [KSecretD]
            Enabled=false
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.displayManager.sddm.enable = true;
      services.displayManager.autoLogin = lib.mkIf (cfg.autoLogin != "") {
        enable = true;
        user = cfg.autoLogin;
      };

      services.desktopManager.plasma6.enable = true;
    }

    (lib.mkIf (cfg.secretService == "gnome-keyring") {
      # gnome-keyring as the Secret Service provider (desktop-agnostic,
      # works well when switching between DEs).
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.login.enableGnomeKeyring = true;
      # Note: sddm PAM gnome-keyring integration is intentionally omitted —
      # with autoLogin enabled the PAM password path is skipped entirely, so
      # it provides no benefit and causes sysinit-reactivation.target to hang
      # during nixos-rebuild switch.
    })

    (lib.mkIf (cfg.secretService == "oo7") {
      # Experimental oo7 provider. The daemon (oo7-server) ships a systemd
      # user unit and a DBus activation file for org.freedesktop.secrets, so
      # it starts on demand. Prompts are handled by Plasma's ksecretprompter.
      # gnome-keyring is left disabled so it doesn't compete for the name.
      systemd.packages = [ pkgs.oo7-server ];
      services.dbus.packages = [ pkgs.oo7-server ];
      environment.systemPackages = [ pkgs.oo7 ]; # oo7-cli, handy for inspection

      # Agenix secret: the keyring encryption password.
      # Before setting secretService = "oo7" on a host for the first time, create
      # the secret file (choose a strong password when prompted):
      #   nix-shell -p agenix --run "agenix -e secrets/oo7-keyring-password.age"
      age.secrets.oo7-keyring-password = {
        file = ../secrets/oo7-keyring-password.age;
        path = "/run/agenix/oo7-keyring-password";
        owner = username;
        mode = "400";
      };

      # Drop-in override for the oo7 secret-service user unit.
      # - Clear ImportCredential= (upstream default, needs a TPM/systemd credstore).
      # - Set LoadCredential= pointing at the agenix secret instead.
      # Systemd reads LoadCredential before the service sandbox (PrivateUsers=)
      # is active, so there is no permission issue.
      #
      # IMPORTANT: oo7-server ships TWO independent units with identical content:
      #   * oo7-daemon.service
      #   * dbus-org.freedesktop.secrets.service
      # They are NOT systemd aliases of each other (no Alias= in [Install]), so a
      # drop-in on one does not apply to the other. The DBus activation file
      # (org.freedesktop.secrets → SystemdService=dbus-org.freedesktop.secrets.service)
      # starts the *dbus-org...* unit at boot, so the credential drop-in MUST live
      # on that unit — otherwise the boot daemon never sees the credential and
      # falls back to prompting.
      #
      # NOTE: the agenix secret must NOT contain a trailing newline — oo7 reads
      # the credential file verbatim and the keyring password must match exactly.
      systemd.user.services."dbus-org.freedesktop.secrets" = {
        overrideStrategy = "asDropin";
        serviceConfig = {
          ImportCredential = ""; # clears the upstream list directive
          LoadCredential =
            "oo7.keyring-encryption-password:${config.age.secrets.oo7-keyring-password.path}";
        };
      };
    })
  ]);
}

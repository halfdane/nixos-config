{ config, lib, ... }:

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
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm.enable = true;
    services.displayManager.autoLogin = lib.mkIf (cfg.autoLogin != "") {
      enable = true;
      user = cfg.autoLogin;
    };

    services.desktopManager.plasma6.enable = true;

    # Use gnome-keyring as the Secret Service provider (desktop-agnostic,
    # works well when switching between DEs).
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
    # Note: sddm PAM gnome-keyring integration is intentionally omitted —
    # with autoLogin enabled the PAM password path is skipped entirely, so
    # it provides no benefit and causes sysinit-reactivation.target to hang
    # during nixos-rebuild switch.
    # To avoid a keyring password prompt on first use, set an empty keyring
    # password once via `seahorse`.
  };
}

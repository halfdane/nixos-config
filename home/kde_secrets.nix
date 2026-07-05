{ config, lib, osConfig, ... }:

# Single place for the per-user Secret Service / KWallet configuration.
#
# Unlike the other home/ modules, this one has no enable flag of its own: it is
# driven entirely by the system-level toggle `services.kde.secretService`
# (defined in nixos/kde.nix) so there is a single source of truth. It only acts
# when plasma-manager is active on the host (programs.plasma.enable).
#
# In every case KDE's own KWallet subsystem is disabled: a dedicated Secret
# Service provider (gnome-keyring or oo7) is used instead, so KWallet must not
# compete for the org.freedesktop.secrets D-Bus name or prompt for its own
# password.
#
# When the provider is "oo7", KDE's ksecretd daemon is additionally disabled and
# a one-time migration of existing KWallet secrets into the 3rd-party provider
# is triggered, per the KDE devs' documented switch procedure:
#   https://planet.kde.org/marco-martin-2026-01-30-kwallet-secretservice-oo7-the-story-so-far/
let
  provider = osConfig.services.kde.secretService;
in
{
  config = lib.mkIf config.programs.plasma.enable (lib.mkMerge [
    {
      # Disable the KWallet subsystem regardless of provider.
      programs.plasma.configFile.kwalletrc = {
        Wallet.Enabled = false;
        Wallet."First Use" = false;
      };
    }

    (lib.mkIf (provider == "oo7") {
      # oo7 provider: stop KDE's ksecretd Secret Service daemon and migrate any
      # existing KWallet secrets into the 3rd-party provider (one-time).
      programs.plasma.configFile.kwalletrc = {
        Migration.MigrateTo3rdParty = true;
        KSecretD.Enabled = false;
      };
    })
  ]);
}

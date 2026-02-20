{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.fetching;
  # Prefer ada package, fallback to default, allow override
  package = cfg.package or inputs.fetching.packages.${pkgs.system}.ada or inputs.fetching.packages.${pkgs.system}.default;
in {
  options.services.fetching = {
    enable = mkEnableOption "fetching Spotify downloader";
    package = mkOption {
      type = types.package;
      default = inputs.fetching.packages.${pkgs.system}.ada or inputs.fetching.packages.${pkgs.system}.default;
      description = "fetching package derivation to use.";
    };
    port = mkOption {
      type = types.port;
      default = 9733;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ package ];

    systemd.services.fetching = {
      description = "fetching - Spotify Downloader";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "fetching";
        Group = "fetching";
        StateDirectory = "fetching";
        WorkingDirectory = "%S/fetching";
        ExecStart = "${package}/bin/fetching server --port ${toString cfg.port} --credentials-file %S/fetching/secrets.json";

        # Security
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        LockPersonality = true;
        # Optional: add these for extra hardening if desired
        # ProtectKernelModules = true;
        # ProtectControlGroups = true;

        Restart = "always";
        RestartSec = 10;
      };
    };

    users.users.fetching = {
      isSystemUser = true;
      group = "fetching";
    };
    users.groups.fetching = { };
  };
}

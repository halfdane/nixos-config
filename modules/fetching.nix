{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.fetching;
  # Prefer ada package, fallback to default, allow override
  package = cfg.package or inputs.fetching.packages.${pkgs.system}.ada or inputs.fetching.packages.${pkgs.system}.default;
in {
  options.services.fetching = {
    enable = mkEnableOption "FETCHing Spotify downloader";
    package = mkOption {
      type = types.package;
      default = inputs.fetching.packages.${pkgs.system}.ada or inputs.fetching.packages.${pkgs.system}.default;
      description = "FETCHing package derivation to use.";
    };
    secretPath = mkOption {  # Renamed, mkIf-safe
      type = types.nullOr types.str;
      default = null;
      description = "Path to credentials file (agenix).";
    };
    port = mkOption {
      type = types.port;
      default = 9733;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ package ];

    systemd.services.fetching = {
      description = "FETCHing - Spotify Downloader";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "fetching";
        Group = "fetching";
        WorkingDirectory = "/var/lib/fetching";
        ExecStart = let
          credsArg = optionalString (cfg.secretPath != null) "--credentials-file ${cfg.secretPath} ";
        in "${package}/bin/fetching ${credsArg}--port ${toString cfg.port}";
        Restart = "always";
        RestartSec = 10;
      };
    };

    users.users.fetching = {
      isSystemUser = true;
      group = "fetching";
    };
    users.groups.fetching = { };

    systemd.tmpfiles.rules = [ "d /var/lib/fetching 0750 fetching fetching - -" ];
  };
}

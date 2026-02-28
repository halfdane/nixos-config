{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.fetching;
  package = cfg.package or inputs.fetching.packages.${pkgs.system}.default;
in {
  options.services.fetching = {
    enable = mkEnableOption "fetching Spotify downloader";
    package = mkOption {
      type = types.package;
      default = inputs.fetching.packages.${pkgs.system}.default;
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
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "fetching";
        Group = "fetching";
        WorkingDirectory = "/var/lib/fetching";
        Environment = [ "HOME=/tmp" ];
        ExecStart = "${package}/bin/fetching server --port ${toString cfg.port} --credentials-file %S/fetching/secrets.json -o /data/Music";
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

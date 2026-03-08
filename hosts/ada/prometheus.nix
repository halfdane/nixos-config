{ config, lib, pkgs, ... }:
let
  node-exporter-btrfs = pkgs.writeShellApplication {
    name = "node-exporter-btrfs";
    runtimeInputs = [ pkgs.btrfs-progs pkgs.gawk pkgs.coreutils pkgs.moreutils ];
    text = ''
      # Directories passed as args
      set -eu -o pipefail
      
      BTRFS_USAGE_REPORT=$(for DIR in "$@"; do
        USED_BYTES=$(btrfs filesystem du --raw -s "$DIR" | tail -1 | awk '{print $1}')
        SAFE_DIR=$(echo "$DIR" | sed 's|^/||; s|/|_|g')
        echo "$DIR -> $SAFE_DIR: $USED_BYTES bytes used" >&2
        cat << EOF
# HELP btrfs_used_bytes BTRFS subvolume usage in bytes
# TYPE btrfs_used_bytes gauge
btrfs_used_bytes{dir="''${SAFE_DIR}"} $USED_BYTES
EOF
      done)

      mkdir -p /var/lib/node_exporter/textfile_collector
      PROM_FILE=/var/lib/node_exporter/textfile_collector/btrfs_usage.prom
      printf "%s\n" "$BTRFS_USAGE_REPORT" > "$PROM_FILE"
    '';
  };
in
{
  options.prometheus = {
    enable = lib.mkEnableOption "Prometheus server and Node Exporter";
    node-exporter-btrfs.enable = lib.mkEnableOption "Node Exporter Btrfs usage reporting";
    node-exporter-btrfs.directoriesToReport = lib.mkOption {
      description = "List of directories to report Btrfs usage for.";
      type = lib.types.listOf lib.types.str;
      default = [ "/data" ];
    };
  };

  config = lib.mkIf config.prometheus.enable {
    services.prometheus = {
      enable = true;
      scrapeConfigs = [{
        job_name = "node";
        static_configs = [{ targets = ["localhost:9100"]; }];
      }];
      exporters.node = {
        enable = true;
        extraFlags = [ "--collector.textfile.directory=/var/lib/node_exporter/textfile_collector" ];
      };
    };
    # report deployment changes to node exporter
    system.activationScripts.writeSystemVersion = {
      text = ''
        mkdir -p /var/lib/node_exporter/textfile_collector
        echo "nixos_system_version{version=\"$(readlink -f /run/current-system | xargs basename)\"} 1" \
          > /var/lib/node_exporter/textfile_collector/nixos_system_version.prom
      '';
    };
    systemd.tmpfiles.rules = [
      "d /var/lib/node_exporter/textfile_collector 0775 node-exporter node-exporter - -"
      "Z /var/lib/node_exporter/textfile_collector 0775 node-exporter node-exporter - -"  # Z=recursive
    ];

    #run the reporter on boot and whenever the system version changes as well as every five minutes
    systemd.services.node-exporter-btrfs-usage = lib.mkIf config.prometheus.node-exporter-btrfs.enable {
      description = "Node Exporter Btrfs Usage Reporter";
      after = [ "local-fs.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "node-exporter";
        Group = "node-exporter";
        ExecStart = "${node-exporter-btrfs}/bin/node-exporter-btrfs ${lib.concatStringsSep " " config.prometheus.node-exporter-btrfs.directoriesToReport}";
        # Hardening
        ReadWritePaths = "/var/lib/node_exporter/textfile_collector";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
      };
    };

    systemd.timers.node-exporter-btrfs-usage = lib.mkIf config.prometheus.node-exporter-btrfs.enable {
      description = "Timer for node-exporter-btrfs-usage regeneration";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "5min";
        Unit = "node-exporter-btrfs-usage.service";
      };
    };

    services.nginx.virtualHosts."prometheus.micasaestu.casa" = {
      useACMEHost = "micasaestu.casa";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:9090";
        proxyWebsockets = true;
      };
    };
  };
}

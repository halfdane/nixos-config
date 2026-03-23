{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.services.prometheus.enable {
    services.prometheus = {
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

  };
}

{ config, lib, pkgs, ... }: {
  options.music = {
    dir = lib.mkOption {
      type = lib.types.str;
      example = "/data";
    };
  };

  config = {
    # enable quota for size reporting
    systemd.services.btrfs-quotas = {
      description = "Btrfs Quotas for ${config.music.dir}";
      after = [ "local-fs.target" ];
      wantedBy = [ "multi-user.target" "navidrome.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${lib.getBin pkgs.btrfs-progs}/bin/btrfs quota enable ${config.music.dir}
      '';
    };
  };
}

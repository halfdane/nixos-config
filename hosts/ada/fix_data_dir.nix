{ config, lib, pkgs, ... }: {
  options.music = {
    dir = lib.mkOption {
      type = lib.types.str;
      example = "/data";
    };
    group = lib.mkOption {
      type = lib.types.str;
      default = "music";
    };
    members = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = {
    users.groups.${config.music.group} = lib.mkIf (config.music.members != [ ]) {
      members = config.music.members;
    };

    systemd.tmpfiles.rules = lib.optionals (config.music.dir != "") [
      "d ${config.music.dir} 0775 fetching ${config.music.group} - -"
      "Z ${config.music.dir},fetching:${config.music.group} 2775"
    ];

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

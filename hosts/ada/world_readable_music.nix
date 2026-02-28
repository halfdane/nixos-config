# host/modules/filesystem.nix
{ config, lib, pkgs, ... }: 
let
  cfg = lib.mkOption {
    type = lib.types.submodule {
      options = {
        dir = lib.mkOption {
          type = lib.types.str;
          example = "/data/Music";
          description = "Music directory path";
        };
        group = lib.mkOption {
          name = "music";
          type = lib.types.str;
          default = "music";
          description = "Group name for music sharing";
        };
        members = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Users in music group";
        };
      };
    };
  };
in {
  options.music = cfg;

  config = lib.mkIf (cfg.members != [ ]) {
    users.groups.${cfg.group} = {
      members = cfg.members;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dir} 0775 fetching ${cfg.group} - -"
      "Z ${cfg.dir},fetching:${cfg.group} 2775"
    ];
  };
}

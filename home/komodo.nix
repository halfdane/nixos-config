{ config, lib, pkgs, ... }:
let
  cfg = config.programs.komodo;
in
{
  options.programs.komodo.enable = lib.mkEnableOption "KomoDo, the KDE todo.txt manager";

  config = lib.mkIf cfg.enable (lib.mkMerge [
    { home.packages = [ pkgs.kdePackages.komodo ]; }

    (lib.mkIf config.programs.plasma.enable {
      programs.plasma.configFile.komodorc.General = {
        TodoFilePath = "file://${config.programs.todo.directory}/todo.txt";
        AutoInsertCreationDate = true;
        AutoReloadOnExternalChange = true;
      };
    })
  ]);
}

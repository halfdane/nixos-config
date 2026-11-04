{ config, lib, pkgs, ... }:
let
  usesKeepass = lib.elem pkgs.keepassxc config.home.packages;
in
{

  config = lib.mkIf usesKeepass {
    home.file."${config.xdg.configHome}/keepassxc/keepassxc.ini" = {
      source = lib.mkForce (
        config.lib.file.mkOutOfStoreSymlink /home/user/nixos-config/home/keepassxc_settings.ini
      );
      force = lib.mkForce true;
    };


    programs.plasma.shortcuts."org.keepassxc.KeePassXC".autotype = 
      lib.mkIf (config.programs.plasma.enable) "Meta+A";
  };
}

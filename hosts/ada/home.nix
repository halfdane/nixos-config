# Minimal home configuration for ada
{ config, pkgs, ... }:
{
  home.username = "halfdane";
  home.homeDirectory = "/home/halfdane";

  programs.beets = {
    enable = true;
    settings = {
      directory = "/data/Music";
      library = "/data/Music/library.db";
      plugins = [ "web" "spotify" ];
    };
  };
}

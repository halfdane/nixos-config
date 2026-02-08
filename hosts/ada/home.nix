# Minimal home configuration for ada
{ config, pkgs, ... }:
{
  home.username = "halfdane";
  home.homeDirectory = "/home/halfdane";

  programs.vim.enable = true;
  programs.git.enable = true;
}

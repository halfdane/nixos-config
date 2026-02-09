# Minimal home configuration for ada
{ config, pkgs, ... }:
{
  home.username = "halfdane";
  home.homeDirectory = "/home/halfdane";

  # Is globally enabled in common
  # keeping it here as example of how to enable programs host-specific
  # programs.vim.enable = true;
}

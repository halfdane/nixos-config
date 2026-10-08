{ config, lib, pkgs, ... }:

# Global Auto-Type shortcut for KeePassXC.
#
# Like kde_secrets.nix this has no enable flag: it activates automatically when
# plasma-manager is active on the host (programs.plasma.enable) and keepassxc is
# installed through home.packages.
let
  usesKeepass = lib.elem pkgs.keepassxc config.home.packages;
in
{
  config = lib.mkIf (config.programs.plasma.enable && usesKeepass) {
    programs.plasma.shortcuts."org.keepassxc.KeePassXC".autotype = "Meta+A";
  };
}

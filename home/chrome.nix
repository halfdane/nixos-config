{ config, pkgs, lib, ... }:
{
  # Enable on a host by setting: programs.chromium.enable = true;
  # Google Chrome is used on x86_64-linux; Chromium is used on all other platforms
  # (e.g. aarch64-linux) since google-chrome does not support them.
  # Requires nixpkgs.config.allowUnfree = true on x86_64-linux hosts.
  programs.chromium = lib.mkIf config.programs.chromium.enable {
    package = if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
              then pkgs.google-chrome
              else pkgs.chromium;
  };
}

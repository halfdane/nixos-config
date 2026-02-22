# Tailscale NixOS Module
# Provides a reusable, parameterized Tailscale setup with optional agenix secret integration.

{ config, pkgs, lib, ... }:
{
  options.tailscale = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Tailscale service.";
    };
    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to Tailscale auth key file (can reference agenix secret).";
    };
  };

  config = lib.mkIf config.tailscale.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = config.tailscale.authKeyFile;
    };
  };
}

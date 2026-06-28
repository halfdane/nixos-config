{ config, pkgs, lib, ... }:
{
  programs.ssh = lib.mkIf config.programs.ssh.enable {
    enableDefaultConfig = false;
    settings = {
      "*" = {
        # Add your default SSH settings here
        ForwardAgent = true;
        # Example: Compression = true;
      };
    };
  };
}

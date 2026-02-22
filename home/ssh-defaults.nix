{ config, pkgs, lib, ... }:
{
  programs.ssh = lib.mkIf config.programs.ssh.enable {
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        # Add your default SSH settings here
        forwardAgent = true;
        # Example: compression = true;
      };
    };
  };
}

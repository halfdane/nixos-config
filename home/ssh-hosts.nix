{ config, pkgs, lib, ... }:
{
  programs.ssh = lib.mkIf config.programs.ssh.enable {
    matchBlocks = {
      ada = {
        host = "ada";
        hostname = "10.100.0.1";
        user = "halfdane";
      };
      curie = {
        host = "curie";
        hostname = "192.168.64.6";
        user = "user";
      };
      laptop = {
        host = "laptop";
        hostname = "laptop";
        user = "tvollert";
      };
    };
  };
}

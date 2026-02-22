{ config, pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      ada = {
        host = "ada";
        hostname = "152.53.176.47";
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

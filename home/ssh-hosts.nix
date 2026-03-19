{ config, pkgs, lib, ... }:
{
  programs.ssh = lib.mkIf config.programs.ssh.enable {
    extraConfig = ''
      IdentityFile /run/agenix/user-ssh-key
    '';
    matchBlocks = {
      ada = {
        host = "ada";
        hostname = "10.100.0.1";
        user = "halfdane";
      };
      curie = {
        host = "curie";
        hostname = "192.168.64.8";
        user = "user";
      };
      leguin = {
        host = "leguin";
        hostname = "192.168.178.103";
        user = "tom";
      };
      tubman = {
        host = "tubman";
        hostname = "192.168.178.145";
        user = "user";
      };

    };
  };
}

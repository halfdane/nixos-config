{ config, pkgs, lib, ... }:
{
  programs.ssh = lib.mkIf config.programs.ssh.enable {
    extraConfig = ''
      IdentityFile /run/agenix/user-ssh-key
    '';
    settings = {
      ada = {
        HostName = "10.100.0.1";
        User = "user";
      };
      curie = {
        HostName = "192.168.64.8";
        User = "user";
      };
      leguin = {
        HostName = "192.168.178.103";
        User = "user";
      };
      tubman = {
        HostName = "192.168.178.145";
        User = "user";
      };

    };
  };
}

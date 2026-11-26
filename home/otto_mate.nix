{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.programs.otto_mate;
  package = inputs.otto_mate.packages.${pkgs.stdenv.hostPlatform.system}.default;
  shared = "${package}/share/otto-mate";
in
{
  options.programs.otto_mate.enable = lib.mkEnableOption "otto-mate command line with its opencode agent and skills";

  config = lib.mkIf cfg.enable {
    home.packages = [ package ];

    xdg.configFile."opencode/agents" = {
      source = "${shared}/agents";
      recursive = true;
    };
    xdg.configFile."opencode/skills" = {
      source = "${shared}/skills";
      recursive = true;
    };
  };
}

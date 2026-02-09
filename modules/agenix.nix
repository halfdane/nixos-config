# Agenix NixOS Module
# Centralizes secret file declarations and makes referencing secrets consistent.

{ config, lib, ... }:
{
  options.agenix.secrets = lib.mkOption {
    type = lib.types.attrsOf lib.types.path;
    default = {};
    description = "Mapping of secret names to .age file paths.";
  };

  config = {
    age.secrets = lib.mapAttrs (
      name: path: { file = path; }
    ) config.agenix.secrets;
  };
}

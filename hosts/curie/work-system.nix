{ inputs, ... }:
{
  # All work system-level config lives in the minerva_owl-setup repo, fetched
  # as the `minerva_owl_setup` flake input (see flake.nix).
  # VPN (globalprotect-openconnect) is provided by minerva_owl_setup.
  imports = [
    inputs.minerva_owl_setup.nixosModules.certificates
    inputs.minerva_owl_setup.nixosModules.vpn
  ];

  services.minerva-vpn.enable = true;
}

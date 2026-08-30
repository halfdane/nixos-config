{ inputs, ... }:
{
  # All work system-level config lives in the minerva_owl-setup repo, fetched
  # as the `minerva_owl_setup` flake input (see flake.nix).
  # VPN (globalprotect-openconnect) is provided by minerva_owl_setup.
  imports = [ inputs.minerva_owl_setup.nixosModules.workSystem ];

  # dash0 CLI etc. (see minerva_owl-setup/home/module.nix); useGlobalPkgs = true
  # means overlays must be applied here at the system level, not from within
  # the Home Manager module itself.
  nixpkgs.overlays = [ inputs.minerva_owl_setup.overlays.default ];
}

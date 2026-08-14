{ inputs, ... }:
{
  # All work system-level config lives in the minerva_owl-setup repo, fetched
  # as the `minerva_owl_setup` flake input (see flake.nix).
  # VPN needs `globalprotect-openconnect` in flake inputs (already present).
  imports = [ inputs.minerva_owl_setup.nixosModules.workSystem ];

  # dash0 CLI etc. (see minerva_owl-setup/home/module.nix); useGlobalPkgs = true
  # means overlays must be applied here at the system level, not from within
  # the Home Manager module itself.
  nixpkgs.overlays = [ inputs.minerva_owl_setup.overlays.default ];
}

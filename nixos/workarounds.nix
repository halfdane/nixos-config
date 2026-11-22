{ lib, ... }:

# ALL temporary workarounds live in this file. Nothing else.
#
# Cleanup routine: read this file, check each "REMOVE WHEN", delete what is done.
# Each entry fails at eval time when it looks obsolete.
#
# Rules for a new entry:
#   WHAT         - what the workaround changes
#   WHY          - what breaks without it
#   REMOVE WHEN  - the concrete condition
#   ADDED        - date
#   Add a lib.throwIf that fires when the REMOVE WHEN condition looks true.
#
# Overlays apply to home-manager too (home-manager.useGlobalPkgs = true), so
# this also fixes packages that come from home-manager modules.
{
  nixpkgs.overlays = [
    (final: prev: {

      # WHAT         - adds kdePackages.komodo, built from pkgs/komodo/package.nix.
      # WHY          - nixpkgs does not package KomoDo (KDE todo.txt manager).
      # REMOVE WHEN  - nixpkgs has kdePackages.komodo. Then delete this entry and pkgs/komodo.
      # ADDED        - 2026-11-22
      kdePackages = lib.throwIf (prev.kdePackages ? komodo)
        "workarounds: nixpkgs now has kdePackages.komodo - remove the komodo overlay and pkgs/komodo"
        (prev.kdePackages.overrideScope (kfinal: _: {
          komodo = kfinal.callPackage ../pkgs/komodo/package.nix { };
        }));
    })
  ];
}

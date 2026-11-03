{ lib, ... }:

# ALL temporary workarounds live in this file. Nothing else.
#
# Cleanup routine: read this file, check each "REMOVE WHEN", delete what is done.
# Each entry warns at eval time (visible in `task` output) when it looks obsolete.
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

    })
  ];
}

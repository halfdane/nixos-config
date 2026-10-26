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
#   Add a lib.warnIf that fires when the REMOVE WHEN condition looks true.
#
# Overlays apply to home-manager too (home-manager.useGlobalPkgs = true), so
# this also fixes packages that come from home-manager modules.
{
  nixpkgs.overlays = [
    (final: prev: {

      # WHAT: Relax the websockets version pin of apm-cli.
      # WHY: apm-cli 0.33.0 requires websockets<17, nixpkgs has 17.x. The
      #      runtime-deps check fails the build. apm-cli comes from
      #      minerva_owl_setup (home/modules/packages.nix).
      # RISK: apm-cli is untested against websockets 17.
      # REMOVE WHEN: nixpkgs bumps apm-cli past 0.33.0 and it allows websockets 17.
      # ADDED: 2026-10-26
      apm-cli =
        lib.warnIf (prev.apm-cli.version != "0.33.0")
          "workarounds.nix: apm-cli is now ${prev.apm-cli.version} (was 0.33.0). Check if the websockets relax is still needed."
          (prev.apm-cli.overridePythonAttrs (old: {
            pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "websockets" ];
          }));

      # WHAT: Build KeePassXC from the 2.8.0 release branch.
      # WHY: The release branch has the Wayland portal Auto-Type backend.
      # NOTE: GUI tests and the check phase are off. TestGuiBrowser.cpp at the
      #       pinned rev uses QTEST_DISABLE_KEYPAD_NAVIGATION, which current Qt
      #       no longer defines. The test build failed. The app is unaffected.
      # REMOVE WHEN: nixpkgs ships KeePassXC 2.8.0 or newer.
      # ADDED: see git log (commit acda601)
      keepassxc =
        lib.warnIf (lib.versionAtLeast prev.keepassxc.version "2.8.0")
          "workarounds.nix: nixpkgs has keepassxc ${prev.keepassxc.version}. Remove the 2.8.0 release-branch override."
          (prev.keepassxc.overrideAttrs (old: {
            version = "2.8.0-release-branch";

            src = final.fetchFromGitHub {
              owner = "keepassxreboot";
              repo = "keepassxc";
              rev = "84658ade9a1763dae6108d489a88e503ce3d146d";
              hash = "sha256-PhkMGj9fiCmwuozThEZR43anUbXnZDyn3NgxIntODhc=";
            };

            patches = [ ];

            doCheck = false;

            cmakeFlags = [
              (lib.cmakeFeature "KEEPASSXC_BUILD_TYPE" "Release")
              (lib.cmakeBool "WITH_GUI_TESTS" false)
              (lib.cmakeBool "KPXC_FEATURE_UPDATES" false)
              (lib.cmakeBool "WITH_X11" true)
              (lib.cmakeBool "KPXC_FEATURE_BROWSER" true)
              (lib.cmakeBool "KPXC_FEATURE_SSHAGENT" true)
              (lib.cmakeBool "KPXC_FEATURE_FDOSECRETS" true)
              (lib.cmakeBool "KPXC_FEATURE_NETWORK" true)
            ];

            nativeBuildInputs = with final; [
              asciidoctor
              cmake
              pkg-config
              qt6Packages.qttools
              qt6Packages.wrapQtAppsHook
              wrapGAppsHook3
            ];

            buildInputs = with final; [
              botan3
              curl
              keyutils
              libargon2
              libusb1
              libxkbcommon
              libxi
              libxtst
              minizip
              pcsclite
              qrencode
              qt6Packages.qtbase
              qt6Packages.qtsvg
              readline
              zlib
            ];
          }));

    })
  ];
}

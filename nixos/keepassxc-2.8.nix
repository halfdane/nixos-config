{ lib, pkgs, ... }:

{
  # Temporary override until KeePassXC 2.8.0 is released and packaged in
  # nixpkgs. The release branch contains the Wayland portal Auto-Type backend.
  nixpkgs.overlays = [
    (final: prev: {
      keepassxc = prev.keepassxc.overrideAttrs (old: {
        version = "2.8.0-release-branch";

        src = pkgs.fetchFromGitHub {
          owner = "keepassxreboot";
          repo = "keepassxc";
          rev = "84658ade9a1763dae6108d489a88e503ce3d146d";
          hash = "sha256-PhkMGj9fiCmwuozThEZR43anUbXnZDyn3NgxIntODhc=";
        };

        patches = [];

        cmakeFlags = [
          (lib.cmakeFeature "KEEPASSXC_BUILD_TYPE" "Release")
          (lib.cmakeBool "WITH_GUI_TESTS" true)
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
      });
    })
  ];
}

{
  description = "NixOS configuration for my VM";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
        url = "github:nix-community/home-manager/release-25.11";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    # Optional work configuration (enterprise repo)
    # Note: path: URLs with absolute paths work reliably for local directories
    work-config = {
      url = "path:/home/tvollert/work/work-nixos-config";
      flake = false;
    };
    nixos-aarch64-widevine.url = "github:epetousis/nixos-aarch64-widevine";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, work-config ? null, nixos-aarch64-widevine, ... }:
    let
      system = "aarch64-linux";
      userConfig = import ./user-config.nix;
      hasWorkConfig = work-config != null;
      commonModules = [
        ./configuration.nix
      ] ++ (if hasWorkConfig then [ "${work-config}/work-system.nix" ] else [])
      ++ [
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${userConfig.username} = { config, pkgs, lib, ... }: {
            imports = [ ./home.nix ] ++ (if hasWorkConfig then [ "${work-config}/work-config.nix" ] else [ ]);
          };
        }
        {
          nixpkgs.overlays = [ nixos-aarch64-widevine.overlays.default ];
        }
      ];
    in {
      nixosConfigurations = {
        vm-qemu = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [
            ./hardware-configuration-qemu.nix
            ./qemu-vm.nix
          ];
        };
      };
    };
}

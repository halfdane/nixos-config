{
  description = "NixOS configuration for my machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
        url = "github:nix-community/home-manager/release-25.11";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-aarch64-widevine.url = "github:epetousis/nixos-aarch64-widevine";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-aarch64-widevine, disko, agenix, ... }:
    let
      commonModules = [ 
        ./modules/common/configuration.nix 
        ./modules/tailscale.nix
        ./modules/agenix.nix
        agenix.nixosModules.default
      ];
    in {
      packages = {
        x86_64-linux = agenix.packages.x86_64-linux.default;
        aarch64-linux = agenix.packages.aarch64-linux.default;
      };


      nixosConfigurations = {
        laptop = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs agenix; };
          modules = commonModules ++ [
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.tvollert = { config, pkgs, lib, ... }: {
                imports = [
                  ./modules/common/home.nix
                  ./hosts/laptop/home.nix
                ];
              };
            }
            ./hosts/laptop/configuration.nix
          ];
        };
        ada = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs agenix; };
          modules = commonModules ++ [
            disko.nixosModules.disko
            ./hosts/ada/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.halfdane = { config, pkgs, lib, ... }: {
                imports = [
                  ./modules/common/home.nix
                  ./hosts/ada/home.nix
                ];
              };
            }
          ];
        };
      };
    };
}

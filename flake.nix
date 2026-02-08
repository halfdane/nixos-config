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
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-aarch64-widevine, disko, ... }:
    let
      # No commonModules; move to laptop config
    in {
      nixosConfigurations = {
        laptop = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.tvollert = { config, pkgs, lib, ... }: {
                imports = [
                  ./home.nix
                  ./hosts/laptop/home.nix
                ];
              };
            }
            ./hosts/laptop/configuration.nix
          ];
        };
        ada = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            ./hosts/ada/disko.nix
            ./hosts/ada/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.halfdane = { config, pkgs, lib, ... }: {
                imports = [
                  ./home.nix
                  ./hosts/ada/home.nix
                ];
              };
            }
          ];
        };
      };
    };
}

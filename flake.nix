{
  description = "NixOS configuration for my machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
        url = "github:nix-community/home-manager/master";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-aarch64-widevine.url = "github:epetousis/nixos-aarch64-widevine";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    fetching.url = "github:halfdane/fetching/v0.1.17";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";  # Pin to your nixpkgs
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-aarch64-widevine, disko, agenix, plasma-manager, fetching, ... }:
    let
      nixosModules = [ 
        ./nixos/nix_basics.nix
        ./nixos/tailscale.nix
        ./nixos/fetching.nix
        ./nixos/maestral.nix
        ./nixos/kde.nix
        agenix.nixosModules.default
      ];
      homeModules = [
        ./home/everyone.nix
        ./home/ssh-hosts.nix
        ./home/ssh-defaults.nix
      ];
    in {
      packages = {
        x86_64-linux.default = agenix.packages.x86_64-linux.default;
        aarch64-linux.default = agenix.packages.aarch64-linux.default;
      };

      nixosConfigurations = {
        laptop = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs agenix; };
          modules = nixosModules ++ [
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [ inputs.plasma-manager.homeModules.plasma-manager ];
              home-manager.users.tvollert = { config, pkgs, lib, ... }: {
                imports = homeModules ++ [
                  ./hosts/laptop/home.nix
                  inputs.agenix.homeManagerModules.default
                ];
              };
            }
            ./hosts/laptop/configuration.nix
          ];
        };
        curie = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs agenix; };
          modules = nixosModules ++ [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [ inputs.plasma-manager.homeModules.plasma-manager ];
              home-manager.users.user = { config, pkgs, lib, ... }: {
                imports = homeModules ++ [
                  ./hosts/curie/home.nix
                  inputs.agenix.homeManagerModules.default
                ];
              };
            }
            ./hosts/curie/configuration.nix
          ];
        };

        ada = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs agenix fetching; };
          modules = nixosModules ++ [
            disko.nixosModules.disko
            ./hosts/ada/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.halfdane = { config, pkgs, lib, ... }: {
                imports = homeModules ++ [
                  ./hosts/ada/home.nix
                  inputs.agenix.homeManagerModules.default
                ];
              };
            }
          ];
        };
      };
    };
}

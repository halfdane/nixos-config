{
  description = "NixOS configuration for my machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
        url = "github:nix-community/home-manager/release-25.11";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    
    nixos-aarch64-widevine.url = "github:epetousis/nixos-aarch64-widevine";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-aarch64-widevine, ... }:
    let
      system = "aarch64-linux";
      commonModules = [
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
      ];
    in {
      nixosConfigurations = {
        laptop = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [
            ./hosts/laptop/configuration.nix
          ];
        };
      };
    };
}

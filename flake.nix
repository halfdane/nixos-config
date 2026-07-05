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
    fetching.url = "github:halfdane/fetching";
    fetching.inputs.nixpkgs.follows = "nixpkgs";
    ilias.url = "github:halfdane/ilias";
    prometheus-renderer.url = "github:halfdane/prometheus-renderer";
    prometheus-renderer.inputs.nixpkgs.follows = "nixpkgs";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";  # Pin to your nixpkgs
    };

    nixarr.url = "github:nix-media-server/nixarr";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-aarch64-widevine, 
                      disko, agenix, plasma-manager, fetching, 
                      ilias, nixarr, ... }:
    let
      nixosModules =
        (import ./nixos)
        ++ [
          ./secrets/pubkeys.nix
          inputs.fetching.nixosModules.default
          agenix.nixosModules.default
          ilias.nixosModules.default
          inputs.prometheus-renderer.nixosModules.default
          nixarr.nixosModules.default
        ];
      homeModules = (import ./home);
      mkHost = import ./lib/mkHost.nix {
        inherit nixpkgs nixosModules homeModules disko agenix home-manager inputs;
      };
      hosts = {
        curie = {
          platform = "aarch64-linux";
          username = "user";
          specialArgs = { inherit inputs agenix; };
        };
        ada = {
          platform = "x86_64-linux";
          username = "user";
          specialArgs = { inherit inputs agenix fetching; };
        };
        tubman = {
          platform = "x86_64-linux";
          username = "user";
          specialArgs = { inherit inputs agenix; };
        };
        leguin = {
          platform = "x86_64-linux";
          username = "user";
          specialArgs = { inherit inputs agenix; };
        };
      };
    in {
      packages = {
        x86_64-linux.default = agenix.packages.x86_64-linux.default;
        aarch64-linux.default = agenix.packages.aarch64-linux.default;
      };

      nixosConfigurations = nixpkgs.lib.mapAttrs (name: cfg:
        mkHost {
          hostname = name;
          hostPlatform = cfg.platform;
          specialArgs = cfg.specialArgs;
          extraModules = [ ./hosts/${name}/configuration.nix ];
          username = cfg.username;
          homeImports = [ ./hosts/${name}/home.nix inputs.agenix.homeManagerModules.default ];
          extraHomeManagerModules = cfg.extraHomeManagerModules or [];
        }
      ) hosts;
    };
}

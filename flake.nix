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

    # Pinned to the nixpkgs commit ada's working navidrome was built from.
    # Update only once a navidrome build is confirmed working in a newer commit.
    nixpkgs-navidrome.url = "github:NixOS/nixpkgs/0182a361324364ae3f436a63005877674cf45efb";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";  # Pin to your nixpkgs
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-aarch64-widevine, disko, agenix, plasma-manager, fetching, nixpkgs-navidrome, ilias, ... }:
    let
      nixosModules =
        (import ./nixos)
        ++ [
          ./secrets/pubkeys.nix
          inputs.fetching.nixosModules.default
          agenix.nixosModules.default
          ilias.nixosModules.default
          inputs.prometheus-renderer.nixosModules.default
        ];
      homeModules = (import ./home);
      mkHost = import ./lib/mkHost.nix {
        inherit nixpkgs nixosModules homeModules disko agenix home-manager inputs;
      };
      hosts = {
        curie = {
          platform = "aarch64-linux";
          nixosModules = import ./nixos;
          homeModules = import ./home;
          username = "user";
          specialArgs = { inherit inputs agenix; };
          extraHomeManagerModules = [ inputs.plasma-manager.homeModules.plasma-manager ];
        };
        ada = {
          platform = "x86_64-linux";
          username = "halfdane";
          specialArgs = { inherit inputs agenix fetching; nixpkgsNavidrome = nixpkgs-navidrome.legacyPackages.x86_64-linux; };
        };
        tubman = {
          platform = "x86_64-linux";
          nixosModules = import ./nixos;
          homeModules = import ./home;
          username = "user";
          specialArgs = { inherit inputs agenix; };
          extraHomeManagerModules = [ inputs.plasma-manager.homeModules.plasma-manager ];
        };
      };
      system = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = {
        x86_64-linux.default = agenix.packages.x86_64-linux.default;
        aarch64-linux.default = agenix.packages.aarch64-linux.default;
      };
      nix.channel.enable = false;

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

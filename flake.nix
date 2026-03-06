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
      nixosModules = [ 
        ./nixos/nix_basics.nix
        ./nixos/tailscale.nix
        ./nixos/fetching.nix
        ./nixos/maestral.nix
        ./nixos/kde.nix
        agenix.nixosModules.default
        ilias.nixosModules.default
        inputs.prometheus-renderer.nixosModules.default
      ];
      homeModules = [
        ./home/everyone.nix
        ./home/ssh-hosts.nix
        ./home/ssh-defaults.nix
        ./home/vscode.nix 
        ./home/firefox.nix
        ./home/chrome.nix
      ];
    in {
      packages = {
        x86_64-linux.default = agenix.packages.x86_64-linux.default;
        aarch64-linux.default = agenix.packages.aarch64-linux.default;
      };
      nix.channel.enable = false;

      nixosConfigurations = {
        laptop = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs agenix; };
          modules = nixosModules ++ [
            { nixpkgs.hostPlatform = "aarch64-linux"; }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [ inputs.plasma-manager.homeModules.plasma-manager ];
              home-manager.users.tvollert = { config, pkgs, lib, ... }: {
                imports = homeModules ++ [
                  ./hosts/laptop/home.nix
                  ./home/plasma_hacking.nix
                  inputs.agenix.homeManagerModules.default
                ];
              };
            }
            ./hosts/laptop/configuration.nix
          ];
        };
        curie = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs agenix; };
          modules = nixosModules ++ [
            { nixpkgs.hostPlatform = "aarch64-linux"; }
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [ inputs.plasma-manager.homeModules.plasma-manager ];
              home-manager.users.user = { config, pkgs, lib, ... }: {
                imports = homeModules ++ [
                  ./hosts/curie/home.nix
                  ./home/plasma_hacking.nix
                  inputs.agenix.homeManagerModules.default
                ];
              };
            }
            ./hosts/curie/configuration.nix
          ];
        };

        ada = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs agenix fetching; nixpkgsNavidrome = nixpkgs-navidrome.legacyPackages.x86_64-linux; };
          modules = nixosModules ++ [
            { nixpkgs.hostPlatform = "x86_64-linux"; }
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

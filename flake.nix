{
  description = "NixOS configuration for my machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
        url = "github:nix-community/home-manager/master";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fetching = {
      url = "github:halfdane/fetching";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ilias = {
      url = "github:halfdane/ilias";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    prometheus-renderer = {
      url = "github:halfdane/prometheus-renderer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pulls extensions directly from the VS Code Marketplace / Open VSX, e.g.
    # Pylance, which isn't packaged in nixpkgs (proprietary license). See
    # home/vscode.nix for usage.
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    globalprotect-openconnect.url = "github:yuezk/GlobalProtect-openconnect";

    agenix.url = "github:ryantm/agenix";
    nixos-aarch64-widevine.url = "github:epetousis/nixos-aarch64-widevine";
    nixarr.url = "github:nix-media-server/nixarr";

    # Private repo holding the agenix-encrypted secrets and agenix recipient
    # rules. Kept out of this (public) repo. flake = false: it is a plain file
    # tree, consumed via "${inputs.secrets}/<name>.age".
    secrets = {
      url = "git+ssh://git@github.com/halfdane/nixos-secrets.git";
      flake = false;
    };

    # Minerva team dev tooling (curie only). Fetched via the "github-otto-ec"
    # SSH host alias (see hosts/curie/home.nix) instead of plain github.com:
    # git's gitdir-based work/personal key switch doesn't apply here because
    # Nix clones flake inputs into its own cache, not under ~/work/.
    minerva_owl_setup = {
      url = "git+ssh://git@github-otto-ec/otto-ec/minerva_owl-setup.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-aarch64-widevine, 
                      disko, agenix, plasma-manager, fetching, 
                      ilias, nixarr, minerva_owl_setup, ... }:
    let
      nixosModules =
        (import ./nixos)
        ++ [
          "${inputs.secrets}/pubkeys.nix"
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
          specialArgs = { inherit inputs agenix; };
          extraHomeManagerModules = [ minerva_owl_setup.homeManagerModules.default ];
        };
        ada = {
          platform = "x86_64-linux";
          specialArgs = { inherit inputs agenix fetching; };
        };
        leguin = {
          platform = "x86_64-linux";
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
          username = cfg.username or "user";
          homeImports = [ ./hosts/${name}/home.nix inputs.agenix.homeManagerModules.default ];
          extraHomeManagerModules = cfg.extraHomeManagerModules or [];
        }
      ) hosts;
    };
}

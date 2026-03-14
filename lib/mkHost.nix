{ nixpkgs, nixosModules, homeModules, disko, agenix, home-manager, inputs, ... }:
{ hostname, hostPlatform, extraModules ? [], specialArgs ? {}, homeManagerUser, homeImports, extraHomeManagerArgs ? {}, extraHomeManagerModules ? [], ... }:
  nixpkgs.lib.nixosSystem {
    inherit specialArgs;
    modules = nixosModules ++ [
      { nixpkgs.hostPlatform = hostPlatform; }
      disko.nixosModules.disko
    ] ++ extraModules ++ [
      home-manager.nixosModules.home-manager
      (
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = extraHomeManagerModules ++ [inputs.plasma-manager.homeModules.plasma-manager];
          home-manager.users.${homeManagerUser} = { config, pkgs, lib, ... }:
            {
              imports = homeModules ++ homeImports;
            } // extraHomeManagerArgs;
        }
      )
    ];
  }
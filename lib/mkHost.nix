{ nixpkgs, nixosModules, homeModules, disko, agenix, home-manager, inputs, ... }:
{ hostname, 
  hostPlatform, 
  extraModules ? [], 
  specialArgs ? {}, 
  username, 
  homeImports, 
  extraHomeManagerArgs ? {}, 
  extraHomeManagerModules ? [], 
  ... 
}:
  nixpkgs.lib.nixosSystem {
    specialArgs = specialArgs // { inherit username hostname; };
    modules = nixosModules ++ [
      { nixpkgs.hostPlatform = hostPlatform; }
      disko.nixosModules.disko
    ] ++ extraModules ++ [
      home-manager.nixosModules.home-manager
      (
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # plasma-manager is imported for every host because the always-loaded
          # home/plasma_hacking.nix module references programs.plasma options,
          # which must exist even when that module is disabled (mkIf only gates
          # the value, not the option-existence check). Kept here so it is
          # imported exactly once rather than also via extraHomeManagerModules.
          home-manager.sharedModules = extraHomeManagerModules ++ [inputs.plasma-manager.homeModules.plasma-manager];
          home-manager.users.${username} = { config, pkgs, lib, ... }:
            {
              imports = homeModules ++ homeImports;
            } // extraHomeManagerArgs;
        }
      )
    ];
  }
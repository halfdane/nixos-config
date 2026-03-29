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
    specialArgs = specialArgs // { username = username; hostname = hostname; };
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
          home-manager.users.${username} = { config, pkgs, lib, ... }:
            {
              imports = homeModules ++ homeImports;
            } // extraHomeManagerArgs;
        }
      )
    ];
  }
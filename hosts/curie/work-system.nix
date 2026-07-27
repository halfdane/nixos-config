{ ... }:
let
  # All work system-level config lives in the minerva_owl-setup repo.
  # Requires --impure (see Taskfile.yml); absent before `task repos:clone`, active after.
  # VPN needs `globalprotect-openconnect` in flake inputs (already present).
  minervaPath = "/home/user/work/minerva/minerva_owl-setup";
in
{
  imports = if builtins.pathExists "${minervaPath}/nixos/default.nix"
    then [ (import "${minervaPath}/nixos/default.nix") ]
    else [];
}

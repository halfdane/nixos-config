# Installation for curie

```bash
nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config hosts/curie/hardware-configuration.nix root@192.168.64.6 --flake .#curie --print-build-logs
```

# Updating for curie (main machine)

run 
```bash
sudo nixos-rebuild switch --flake .#laptop
```

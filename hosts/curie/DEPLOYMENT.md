# Curie (laptop)

## Day-to-day deploy

From curie itself:

```bash
task                 # deploy to curie (the default task)
# or explicitly:
task deploy:curie
```

## First install

1. Boot the NixOS installer.
2. Create `hosts/curie/user-config.nix` from the template (gitignored, contains username/name/git identity):
   ```bash
   cp hosts/curie/user-config.nix.template hosts/curie/user-config.nix
   # edit it
   git add -f hosts/curie/user-config.nix
   ```
3. Run nixos-anywhere (replace IP with the installer's address):
   ```bash
   nix run github:nix-community/nixos-anywhere -- \
     --generate-hardware-config nixos-generate-config hosts/curie/hardware-configuration.nix \
     root@<installer-ip> \
     --flake .#curie \
     --print-build-logs
   ```

## WireGuard

Curie is peer `10.100.0.2`. The WireGuard connection is a plain NetworkManager profile — not managed by NixOS or agenix.

To set it up on a fresh install, SSH to ada and run `wg-add-peer curie 10.100.0.2`, then import the printed config:

```bash
# on curie, after saving the printed config as curie.conf:
nmcli connection import type wireguard file ada_vpn.conf
```

The profile persists in NetworkManager across reboots. If the peer entry is already in ada's `wireguard.peers` (it is), there is no need to redeploy ada — just re-import the client config.
If you don't have the client config at hand, just remove the peer config, deploy and run `wg-add-peer` as described above.

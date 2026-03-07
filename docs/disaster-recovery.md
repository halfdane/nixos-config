# Disaster Recovery

## Ada: broken config (still boots, VPN reachable)

Roll back the NixOS generation:

```bash
ssh ada   # requires VPN active on curie or phone
sudo nix-env -p /nix/var/nix/profiles/system --rollback
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

List available generations if you need to jump further back:

```bash
sudo nix-env -p /nix/var/nix/profiles/system --list-generations
sudo nix-env -p /nix/var/nix/profiles/system --switch-generation <N>
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

## Ada: broken WireGuard (SSH not reachable)

Use the netcup KVM console (SCP panel → KVM → start console). You get a root shell without needing network access.

From there, roll back exactly as above.

If you broke the boot entirely, use rescue mode (see below).

## Ada: full wipe / fresh install

1. In the netcup SCP panel: **Media → Rescue System → Boot into rescue**.
2. From curie (or any machine with this repo):

```bash
nix run github:nix-community/nixos-anywhere -- \
  root@152.53.176.47 \
  --flake .#ada \
  --print-build-logs
```

3. After install, regenerate the hardware config if disk layout changed:

```bash
ssh root@152.53.176.47 nixos-generate-config --show-hardware-config \
  > hosts/ada/hardware-configuration-ada.nix
```

4. Commit and redeploy normally.

> **Note:** nixos-anywhere uses the rescue system's network — SSH goes to the public IP here because the WireGuard tunnel doesn't exist yet.

## Agenix: need to decrypt a secret manually

The disaster-recovery key (`dr_from_keepass`) is stored in KeePass and can decrypt every secret in this repo.

1. Export the private key from KeePass to a temp file (or use `ssh-add` with it).
2. Decrypt:

```bash
cd secrets
agenix -d <secret>.age --identity /path/to/dr_key
```

3. Delete the temp key file when done.

## Agenix: re-encrypt all secrets for a new host key

This is needed after a full wipe of ada or curie (the host's ed25519 key changes).

1. Get the new host's public key:

```bash
ssh-keyscan <host-ip> | grep ed25519
```

2. Update `secrets/secrets.nix` with the new key.
3. Re-encrypt all affected secrets. You need a key that can currently decrypt them — either the `dr_from_keepass` key or the old host key (if still available):

```bash
cd secrets
agenix -r -i /path/to/identity
```

This re-encrypts every secret defined in `secrets.nix` to the updated key set.

## Agenix: add a completely new secret

```bash
# Generate a random secret (example: 64-byte hex)
dd if=/dev/urandom bs=1 count=64 status=none | xxd -p -c 64

# Add an entry to secrets/secrets.nix, then:
cd secrets
agenix -e <newname>.age
```

Declare it in the relevant host config:

```nix
age.secrets."newname".file = ./../../secrets/newname.age;
# Use config.age.secrets."newname".path in service configs
```

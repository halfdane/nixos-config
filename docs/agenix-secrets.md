# Handling Secrets with agenix on NixOS

## 1. General Principles
- agenix is the recommended tool for managing secrets in NixOS, using age/rage encryption and SSH keys.
- The encrypted secrets live in a **separate private repo**
  (`git@github.com:halfdane/nixos-secrets.git`), not in this config repo. Clone it
  as a sibling (`../nixos-secrets`) to edit secrets.
- Inside that repo, secrets are stored as `.age` files and referenced by filename
  only (e.g., `mysecret.age`) in `secrets.nix` and on the CLI. Run all `agenix`
  commands from within the `nixos-secrets` checkout.
- This config consumes them via the `secrets` flake input; after changing any
  secret, run `nix flake update secrets` here so the new content is picked up.


## 2. Text Secrets Workflow

All steps 1-2 happen inside a checkout of the private `nixos-secrets` repo.

1. Add a rule to `secrets.nix`:
   ```nix
   {
     "mysecret.age".publicKeys = [ "ssh-ed25519 ..." ];
   }
   ```
2. Create/edit the secret:
   ```bash

    dd if=/dev/urandom bs=1 count=64 status=none | xxd -p -c 64 # user needs to copy this for next command

    agenix -e mysecret.age
   ```
   Commit and push the `nixos-secrets` repo.

3. Reference in NixOS config (in this repo), then `nix flake update secrets`:
   ```nix
   age.secrets.mysecret.file = "${inputs.secrets}/mysecret.age";
   # Use config.age.secrets.mysecret.path in service configs
   ```

## 4. Validation
- Always test decryption with:
  ```bash
  sudo agenix -d mysecret.age --identity /etc/ssh/ssh_host_ed25519_key
  ```
- For binary/hex secrets, compare original and decrypted files with `diff`.

- Get public key of a secret ssh key (here github-work.age):
```
(cd ~/nixos-secrets; ssh-keygen -y -f <(agenix -d github-work.age))
```

- add to known hosts automatically:
```
ssh-keyscan github.com >> ~/.ssh/known_hosts
```

## 5. Troubleshooting
- Ensure `secrets.nix` is valid Nix syntax and all entries are inside `{ ... }`.
- Use the correct filename (no `secrets/` prefix) in agenix commands and `secrets.nix`.
- For binary secrets, always use hex encoding for compatibility.

## 6. References
- [agenix GitHub](https://github.com/ryantm/agenix)
- [NixOS Wiki: agenix](https://nixos.wiki/wiki/Agenix)

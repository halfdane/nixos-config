# Handling Secrets with agenix on NixOS

## 1. General Principles
- agenix is the recommended tool for managing secrets in NixOS, using age/rage encryption and SSH keys.
- Secrets are stored as `.age` files in a `secrets/` directory, but referenced by filename only (e.g., `mysecret.age`) in `secrets.nix` and on the CLI.


## 2. Text Secrets Workflow
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

3. Reference in NixOS config:
   ```nix
   age.secrets.mysecret.file = ./secrets/mysecret.age;
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
(cd ~/nixos-config/secrets; ssh-keygen -y -f <(agenix -d github-work.age))
```

## 5. Troubleshooting
- Ensure `secrets.nix` is valid Nix syntax and all entries are inside `{ ... }`.
- Use the correct filename (no `secrets/` prefix) in agenix commands and `secrets.nix`.
- For binary secrets, always use hex encoding for compatibility.

## 6. References
- [agenix GitHub](https://github.com/ryantm/agenix)
- [NixOS Wiki: agenix](https://nixos.wiki/wiki/Agenix)

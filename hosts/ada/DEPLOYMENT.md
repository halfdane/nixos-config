# Deployment steps for ada (netcup VPS)

1. Boot ada into rescue mode (Media > Rescue System).
2. Use nixos-anywhere from your local machine:
   ```bash
   nix run github:nix-community/nixos-anywhere -- root@152.53.176.47 --flake .#ada --print-build-logs
   ```

3. After install, update `hardware-configuration-ada.nix` with the generated config from ada.
4. Re-deploy as needed using nixos-anywhere.

# Notes
- Log in with: `ssh halfdane@152.53.176.47`

## Updating configuration (recommended)

From your local machine, run:
```bash
nixos-rebuild switch --flake .#ada --target-host halfdane@152.53.176.47 --sudo
```
- This builds locally and deploys to ada using SSH and passwordless sudo.
- No need to rsync or manually rebuild on the server.

## (Legacy) Manual update

If needed, you can still:
```bash
rsync -av --delete ~/nixos-config/ halfdane@152.53.176.47:/home/halfdane/nixos-config/
ssh halfdane@152.53.176.47
cd ~/nixos-config
sudo nixos-rebuild switch --flake ./#ada
```
# Deployment steps for ada (netcup VPS)

1. Boot ada into rescue mode (Media>Rescue System).
2. Use nixos-anywhere from your local machine:
   ```bash
   nix run github:nix-community/nixos-anywhere -- root@152.53.176.47 --flake .#ada --print-build-logs
   ```

3. After install, update `hardware-configuration-ada.nix` with the generated config from ada.
4. Re-deploy as needed using nixos-anywhere.

# Notes
- Log in with: `ssh halfdane@152.53.176.47`


Later: 
```
rsync -av --delete ~/nixos-config/ halfdane@152.53.176.47:/home/halfdane/nixos-config/
ssh halfdane@152.53.176.47
cd ~/nixos-config
sudo nixos-rebuild switch --flake ./#ada
```
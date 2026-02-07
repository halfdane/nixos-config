# NixOS Configuration

Personal NixOS configuration for VM environments.

## Setup

1. **Copy and customize user configuration:**
   ```bash
   cp user-config.nix.template user-config.nix
   # Edit user-config.nix with your details (username, name, Git identities)
   ```

2. **Stage the config file for flakes:**
   ```bash
   git add -f user-config.nix
   ```

3. **Build:**
   ```bash
   sudo nixos-rebuild switch --flake .#vm-qemu
   ```

**Note**: `user-config.nix` is gitignored to keep personal details private.

## Git Identity Management

This configuration automatically switches Git identities based on directory:

- **Personal identity**: Used by default (defined in `user-config.nix`)
- **Work identity**: Automatically used for repos in `~/work/` (also defined in `user-config.nix`)

All identity settings are in one place: `user-config.nix`

## Repository Management

The configuration uses `gh auth switch` to support multiple GitHub accounts with OAuth tokens (no SSH keys).

### Setup Authentication

1. **Authenticate personal account:**
   ```bash
   gh auth login --web
   ```

2. **Authenticate work account:**
   ```bash
   gh auth login --web
   ```

3. **Verify both accounts are added:**
   ```bash
   gh auth status
   ```

### Clone Repositories

- `~/bin/clone-personal-repos` - Switches to personal account and clones to `~/halfdane/`
- `~/bin/clone-work-repos` - Switches to work account and clones to `~/work/`

Add repository URLs to `personalRepos` and `workRepos` in `user-config.nix`, then rebuild.

### Optional: Auto-switch with direnv

direnv is configured to automatically switch `gh` accounts when you enter directories:

```bash
cd ~/halfdane  # Auto-switches to personal account
cd ~/work      # Auto-switches to work account (after you set your username in .envrc)
```

**Benefits:**
- OAuth tokens (not SSH keys) - better security, auto-refresh
- Easy manual switching: `gh auth switch --user USERNAME`
- Optional automatic switching with direnv
- Works seamlessly with conditional Git configs for commit identity
- Git identity (name/email) is still handled by conditional config based on directory
- The SSH config automatically routes `github-work` to github.com with the work key
- Git conditional config ensures commits use the correct identity based on directory

## Multi-Host Configuration (Flake-based)

This repository supports multiple hosts using Nix flakes. Each host has its own configuration in `hosts/<host>/configuration.nix`.

### Host Structure
- Host-specific configs: `hosts/laptop/configuration.nix`, `hosts/<other>/configuration.nix`, etc.

### Host Selection
Hosts are defined in `flake.nix` under `nixosConfigurations`. To add a new host, add a new entry pointing to its config file.

**To build for a specific host:**
```bash
sudo nixos-rebuild switch --flake .#laptop
```
Replace `laptop` with your desired host name as defined in `flake.nix`.

### Adding a New Host
1. Create a new subdirectory in `hosts/` (e.g., `hosts/livingroom/`).
2. Add your host-specific configuration file (e.g., `hosts/livingroom/configuration.nix`).
3. Add a new entry to `nixosConfigurations` in `flake.nix` for the new host.

### Directory Structure
- `~/halfdane/` - Personal projects (uses personal Git identity)
- `~/work/` - Work projects (uses work Git identity automatically)

## Building

For QEMU VM:
```bash
sudo nixos-rebuild switch --flake .#vm-qemu
```

For Apple Virtualization VM (when configured):
```bash
sudo nixos-rebuild switch --flake .#vm-apple
```

# NixOS Setup - Knowledge Document


## Non-Obvious Patterns

### Directory-Based Identity Switching
Uses **direnv** (not Git's includeIf) because:
- Direnv can run `gh auth switch` (Git config cannot)
- Environment variables persist in subdirectories after entering parent directory once
- Subdirectories inherit parent `.envrc` automatically via global `source_up_if_exists`

### Corporate CA Certificates
Corporate networks often require custom CA certificates for HTTPS:
- Configured system-wide via `security.pki.certificateFiles` in `work-system.nix`
- Enables SSL verification to work with corporate VPN and internal services
- NixOS expects certificates in PEM format (text-based)

### Two-Layer Work Config
`work-config.nix` (home-manager) and `work-system.nix` (system-level) because:
- Home-manager cannot set system options like `security.pki.certificateFiles`
- Keeps user-level settings (scripts, direnv) separate from system settings (certificates)

### Work Repo Subdirectories
The `clone-work-repos` script supports `"subdir:owner/repo"` syntax to organize repos:
- Not a standard pattern - custom implementation
- Allows grouping related projects under `~/work/`


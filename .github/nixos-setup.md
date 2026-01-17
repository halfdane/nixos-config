# NixOS Setup - Knowledge Document

## Architecture Decisions

### Why Compartmentalization?
The configuration is split between public (`nixos-config`) and private (`work-nixos-config`) repositories to:
- Share personal NixOS setup publicly without leaking employer name or work email
- Keep work-specific config in enterprise GitHub (not publicly accessible)
- Allow independent version control of work and personal settings

### Why Flake Path Input (Not Git)?
The work-config uses a `path:` flake input rather than a git URL because:
- Work repo is in enterprise GitHub (not publicly accessible)
- Simpler for local development (no authentication needed)
- **Trade-off**: Must manually run `nix flake update work-config` after changes
- This is automated in the `nrs` abbreviation

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

## Gotchas

### Flake Lock Staleness
- Work-config changes don't automatically update (path inputs are locked by lastModified)
- Must explicitly run `nix flake update work-config` or use `--recreate-lock-file`
- Automated in `nrs` command

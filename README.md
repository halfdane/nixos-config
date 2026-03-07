# nixos-config

NixOS flake for two machines.

| Host | Role | Flake target |
|------|------|-------------|
| **ada** | x86_64 netcup VPS — runs all services | `.#ada` |
| **curie** | aarch64 laptop — main workstation | `.#curie` |

## Deploy

```bash
./deploy.sh        # deploys to current host
./deploy.sh ada    # deploys to ada  (WireGuard must be active)
./deploy.sh curie  # deploys to curie
```

## Docs

- [docs/architecture.md](docs/architecture.md) — network topology, services, how to access them
- [docs/disaster-recovery.md](docs/disaster-recovery.md) — ada recovery, agenix secrets recovery
- [docs/agenix-secrets.md](docs/agenix-secrets.md) — day-to-day secret management
- [hosts/ada/DEPLOYMENT.md](hosts/ada/DEPLOYMENT.md) — ada-specific ops
- [hosts/curie/DEPLOYMENT.md](hosts/curie/DEPLOYMENT.md) — curie-specific ops

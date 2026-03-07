# Ada (netcup VPS)

**SSH requires WireGuard active.** Ada's SSH port is not publicly reachable.

```bash
ssh ada          # alias → halfdane@10.100.0.1, defined in home/ssh-hosts.nix
```

## Day-to-day deploy

```bash
./deploy.sh ada  # builds on ada, switches — VPN must be active
```

## First install / full wipe

See [docs/disaster-recovery.md](../../docs/disaster-recovery.md) — requires netcup rescue mode and nixos-anywhere.

## If ada is unreachable via SSH

See [docs/disaster-recovery.md](../../docs/disaster-recovery.md):
- WireGuard broken → netcup KVM console → rollback
- Completely broken → rescue mode → nixos-anywhere

## Services running on ada

See [docs/architecture.md](../../docs/architecture.md) for the full list and URLs.
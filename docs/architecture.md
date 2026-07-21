# Architecture

## Hosts

| Host | Hardware | CPU | RAM | Disk (root) | IP (public) | IP (VPN) | Platform |
|------|----------|-----|-----|-------------|-------------|----------|----------|
| **ada** | netcup VPS 500 G12 (KVM) | 2 vCPU AMD EPYC-Genoa | 3.8 GiB + 5.8 GiB swap (zram+file) | 125 GB (≈105 GB free) | `152.53.176.47` | `10.100.0.1` | x86_64 |
| **curie** | laptop | — | — | — | — | `10.100.0.5` | aarch64 |
| **leguin** | NUC (desktop) | 2× Intel Celeron N2830 @ 2.16 GHz | 3.7 GiB, no swap | 109 GB (≈79 GB free) | — | — (home LAN `192.168.178.103`) | x86_64 |
| **tubman** | — | — | — | — | — | — (home LAN `192.168.178.145`) | — |
| *(phone)* | Android/iOS | — | — | — | — | `10.100.0.3` | — |

> **Resource notes.** ada is memory-constrained: at profiling time only ~730 MiB was available and it was actively swapping (~2 GiB in swap). Disk headroom is ample (~105 GB free). leguin's Celeron N2830 is a weak 2014 low-power part — comparable to ada for transcoding, not faster. Neither box is a strong transcoder. Media for both lives on the Hetzner Storage Box (rclone SFTP mount), not on local disk.

## Network

WireGuard hub-and-spoke. Ada is the hub (server), all other devices are peers.
Actual peers (see `hosts/ada/configuration.nix`): phone `10.100.0.3`,
tv_fritzbox `10.100.0.4`, curie `10.100.0.5`. leguin and tubman are on the home
LAN behind the Fritzbox and reach ada's services through the `tv_fritzbox` tunnel.

```
curie (10.100.0.5) ──────────┐
phone (10.100.0.3) ──────────┤
                             ├── wg-server ── ada (10.100.0.1 / 152.53.176.47:51820)
tv_fritzbox (10.100.0.4) ────┘
   └─ home LAN: leguin (192.168.178.103), tubman (192.168.178.145)
```

- **Split tunnel**: only `10.100.0.0/24` routes through the VPN. Public internet goes direct.
- **DNS**: ada runs dnsmasq on `10.100.0.1:53`. All `*.micasaestu.casa` names resolve to `10.100.0.1`. Clients receive `~micasaestu.casa` as a routing domain so systemd-resolved sends those queries through the tunnel.
- **SSH on ada is not publicly accessible.** `openFirewall = false`. SSH only works from inside the VPN.

### Adding a new WireGuard peer

SSH to ada (VPN must be active), then:

```bash
wg-add-peer <name>          # auto-assigns next available IP
wg-add-peer <name> 10.100.0.X  # explicit IP
```

Copy the printed peer stanza into `hosts/ada/configuration.nix` → `wireguard.peers`, then `task deploy:ada`. Show the QR code to the device.

The peer's private key is printed once and discarded — never stored on the server. If a device is lost, remove its `publicKey` entry and redeploy.

## Services (all on ada)

All services are behind nginx with a Let's Encrypt wildcard cert for `*.micasaestu.casa` (DNS-01 via netcup API, so no inbound port 80 needed for cert renewal).

| Service | URL | Notes |
|---------|-----|-------|
| **ilias** | `https://micasaestu.casa` | |
| **navidrome** | `https://music.micasaestu.casa` | music streaming |
| **fetching** | `https://fetching.micasaestu.casa` | music downloader |
| **prometheus** | port 9090 (VPN only) | scrapes node exporter |

**All services are VPN-only.** Ports 80/443 are not opened in the firewall — nginx is reachable only because `wg-server` is a trusted interface. The only publicly open port is UDP 51820 (WireGuard itself). HTTPS works fine over the tunnel; the cert is obtained via DNS-01 so no inbound port 80 is needed from the internet.

### DNS

`*.micasaestu.casa` resolves to `10.100.0.1` for VPN clients (via dnsmasq) and to `152.53.176.47` for everyone else (public DNS). Both work for HTTPS services.

## Secrets

Managed by [agenix](https://github.com/ryantm/agenix). See [agenix-secrets.md](agenix-secrets.md) for day-to-day operations.

The encrypted secrets live in a **separate private repository**
(`git@github.com:halfdane/nixos-secrets.git`), kept out of this (public) repo.
It is consumed here as the `secrets` flake input (`flake = false`) and referenced
as `"${inputs.secrets}/<name>.age"`. Edit/rekey secrets inside a checkout of that
repo, then run `nix flake update secrets` here to pick up the changes.

Secrets are encrypted to a union of keys — any one key can decrypt:

- `root@ada` host key (for runtime decryption on ada)
- `root@curie` host key (for runtime decryption on curie)
- `tvollert@nixos` user key (for editing secrets from curie)
- `dr_from_keepass` — a dedicated ed25519 key stored in KeePass, used only for disaster recovery

**The KeePass key is the break-glass.** If host keys are lost, any secret can be recovered with it.

## Flake inputs

| Input | Purpose |
|-------|---------|
| `nixpkgs` (unstable) | main package set |
| `home-manager` | user environment |
| `disko` | declarative disk partitioning |
| `agenix` | secret management |
| `nixarr` | media server stack (sonarr/radarr/jellyfin/sabnzbd/…) |
| `fetching` | custom music downloader service |
| `ilias` | custom web app |
| `prometheus-renderer` | custom Grafana-like dashboard |
| `plasma-manager` | KDE Plasma home-manager module |
| `nixos-aarch64-widevine` | Widevine CDM for aarch64 |
| `secrets` | private repo of agenix-encrypted secrets (`flake = false`) |

## Repository layout

```
flake.nix               — inputs, nixosConfigurations for ada + curie
nixos/                  — shared NixOS modules (wireguard, kde, maestral, …)
home/                   — shared home-manager modules
hosts/
  ada/                  — ada host config + DEPLOYMENT.md
  curie/                — curie host config + DEPLOYMENT.md
scripts/
  wg-add-peer           — WireGuard peer onboarding helper
docs/                   — you are here
```

The encrypted secrets are **not** in this repo. They live in the private
`nixos-secrets` repo (agenix `.age` files + `secrets.nix` rules + `pubkeys*.nix`),
pulled in via the `secrets` flake input.

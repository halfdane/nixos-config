#!/usr/bin/env bash
# deploy.sh - Deploy NixOS flake to local or remote host
# Usage: ./deploy.sh [hostname]

set -euo pipefail

HOST="${1-$(hostname)}"

# Host -> login map
# ada is only reachable via WireGuard tunnel (SSH not publicly exposed).
declare -A LOGINS=(
  [curie]="user@192.168.64.6"
  [ada]="halfdane@10.100.0.1"
  [laptop]="tvollert@laptop"
)

if [[ -v "LOGINS[$HOST]" ]]; then
  LOGIN="${LOGINS[$HOST]}"
else
  echo "Unknown host: $HOST" >&2
  exit 1
fi

echo "Updating flake for FETCHing..."
nix flake update fetching

# Local host? (check hostname)
CURRENT_HOST="$(hostname)"

if [[ "$HOST" == "$CURRENT_HOST" ]]; then
  echo "Deploying locally to $HOST..."


  today=$(date +%Y%m%d%H%M%S)
  branch=$(git branch --show-current)
  short_hash=$(git rev-parse --short HEAD)
  NIXOS_LABEL_VERSION="$today.$branch-$short_hash"

  sudo bash -c "NIXOS_LABEL_VERSION=\"$NIXOS_LABEL_VERSION\" nixos-rebuild switch --flake .#\"$HOST\" --no-reexec"

else
  echo "Deploying remotely to $HOST via $LOGIN..."
  nixos-rebuild switch --flake .#"$HOST" \
    --target-host "$LOGIN" \
    --build-host "$LOGIN" \
    --no-reexec \
    --sudo
fi

echo "✅ Deployed $HOST successfully!"

#!/usr/bin/env bash
# deploy.sh - Deploy NixOS flake to local or remote host
# Usage: ./deploy.sh [hostname]

set -euo pipefail

HOST="${1-$(hostname)}"

# Host -> login map (update IPs/users)
declare -A LOGINS=(
  [curie]="user@192.168.64.6"
  [ada]="halfdane@152.53.176.47"
  [laptop]="tvollert@laptop"
)

if [[ -v "LOGINS[$HOST]" ]]; then
  LOGIN="${LOGINS[$HOST]}"
else
  echo "Unknown host: $HOST" >&2
  exit 1
fi

# Local host? (check hostname)
CURRENT_HOST="$(hostname)"
if [[ "$HOST" == "$CURRENT_HOST" ]]; then
  echo "Deploying locally to $HOST..."
  sudo nixos-rebuild switch --flake .#"$HOST" --no-reexec
else
  echo "Deploying remotely to $HOST via $LOGIN..."
  nixos-rebuild switch --flake .#"$HOST" \
    --target-host "$LOGIN" \
    --no-reexec \
    --sudo
fi

echo "✅ Deployed $HOST successfully!"

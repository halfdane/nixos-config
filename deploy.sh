#!/usr/bin/env bash
# deploy.sh - Deploy NixOS flake to local or remote host
# Usage: ./deploy.sh [hostname]

set -euo pipefail

HOST="${1-$(hostname)}"
# Local host? (check hostname)
CURRENT_HOST="$(hostname)"

# expecting host to be in the flake's outputs
mapfile -t existent_hosts < <(nix flake show --json | jq -r '.nixosConfigurations | keys[]')
if [[ ! " ${existent_hosts[*]} " =~ [[:space:]]${HOST}[[:space:]] ]]; then
  echo "Error: Host '$HOST' not found in flake outputs. Available hosts: ${existent_hosts[*]}"
  exit 1
fi

nixos_rebuild_cmd="nixos-rebuild switch --flake .#$HOST --no-reexec"

if [[ "$HOST" == "$CURRENT_HOST" ]]; then
  echo "Deploying locally to $HOST..."
  sudo $nixos_rebuild_cmd
else
  echo "Deploying remotely to $HOST..."
  $nixos_rebuild_cmd \
    --target-host "$HOST" \
    --build-host "$HOST" \
    --sudo
fi

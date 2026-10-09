#!/usr/bin/env bash
set -euo pipefail
# Thin launcher for installer/. No install logic lives here by design.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# NixOS: fzf and python3 from nixpkgs, no venv.
if [ -e /etc/NIXOS ] || grep -qi 'ID=nixos' /etc/os-release 2>/dev/null; then
  exec nix-shell -p python3 fzf --run "python -m installer"
fi

if [ -d "$ROOT/.venv" ]; then
  echo "removing stale .venv (installer has no python deps now)"
  rm -rf "$ROOT/.venv"
fi

command -v python3 >/dev/null 2>&1 || {
  echo "error: python3 required." >&2
  exit 1
}

if ! command -v fzf >/dev/null 2>&1; then
  echo "bootstrap: installing fzf..."
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm fzf
  else
    echo "error: install fzf first." >&2
    exit 1
  fi
fi

exec python3 -m installer "$@"

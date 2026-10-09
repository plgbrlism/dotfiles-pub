#!/usr/bin/env bash
set -euo pipefail
# thin launcher for .installer. no install logic lives here.
# builds .venv (rich, questionary) on first run, then hands over.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# nixos has no system python3, borrow one and re-run under it
if [ -z "${IN_NIX_SHELL:-}" ] &&
   { [ -e /etc/NIXOS ] || grep -qi 'ID=nixos' /etc/os-release 2>/dev/null; }; then
  printf -v cmd '%q ' "$ROOT/install.sh" "$@"
  exec nix-shell -p python3 --run "IN_NIX_SHELL=1 bash $cmd"
fi

command -v python3 >/dev/null 2>&1 || {
  echo "error: python3 required." >&2
  exit 1
}

# reuse the venv only when both deps import
if .venv/bin/python -c 'import rich, questionary' 2>/dev/null; then
  :
elif command -v uv >/dev/null 2>&1; then
  echo "bootstrap: uv venv + rich questionary..."
  uv venv -q .venv
  uv pip install -q -p .venv/bin/python rich questionary
else
  echo "bootstrap: python venv + rich questionary..."
  python3 -m venv .venv
  .venv/bin/pip install -q rich questionary
fi

export PAUL_DOTFILES_ROOT="$ROOT"

# python cannot import a dot-prefixed dir, alias .installer into the venv
SITE="$(.venv/bin/python -c 'import sysconfig;print(sysconfig.get_paths()["purelib"])')"
ln -sfn "$ROOT/.installer" "$SITE/installer"

exec .venv/bin/python -m installer "$@"
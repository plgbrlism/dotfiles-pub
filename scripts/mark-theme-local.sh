#!/usr/bin/env bash
# Marks rizzoo-generated theme outputs as skip-worktree so local
# regenerations (`rizzoo -i <img>`) stay machine-specific and
# `git status` stays clean.
#
# Only paths present on disk are marked, so this is safe to run on
# master (no dynamic baselines) and on dynamic (full set).
# The skip bit is index-local (not pushed); re-run it on every machine.
#
# To undo (e.g. to commit a new baseline):
#   git update-index --no-skip-worktree -- <path>
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PATHS=(
  "apps/cli/btop/.config/btop/themes/dynamic.theme"
  "apps/terminal/alacritty/.config/alacritty/colors/variants/dynamic.toml"
  "apps/cli/starship/.config/starship/variants/dynamic.toml"
  "apps/editor/zed/.config/zed/themes/dynamic.json"
  "apps/terminal/ghostty/.config/ghostty/colors/variants/dynamic.ghostty"
  "apps/wm/sway/.config/sway/colors/variants/dynamic.conf"
  "apps/terminal/kitty/.config/kitty/colors/variants/dynamic.conf"
  "apps/cli/peaclock/.peaclock/variants/dynamic.conf"
  "qt/qt5/.config/qt5ct/colors/dynamic.conf"
  "qt/qt6/.config/qt6ct/colors/dynamic.conf"
  "apps/editor/nvim/.config/nvim/lua/rizzoo/palette.lua"
  "apps/wm/niri/.config/niri/kdl/layout.kdl"
  "apps/tty/xresources/variants/dynamic"
  "apps/cli/cava/.config/cava/config"
  "apps/terminal/foot/.config/foot/color-foot.ini"
  "noctalia-dell/.config/noctalia/palettes/rizzoo.json"
  "noctalia-hp/.config/noctalia/palettes/rizzoo.json"
  "qt/kvantum/.config/Kvantum/KvMaterial/KvMaterial.svg"
  "qt/kvantum/.config/Kvantum/KvMaterial/KvMaterial.kvconfig"
)

EXISTING=()
for p in "${PATHS[@]}"; do
  if [ -e "$p" ]; then
    EXISTING+=("$p")
  fi
done

if [ "${#EXISTING[@]}" -gt 0 ]; then
  git update-index --skip-worktree -- "${EXISTING[@]}"
fi

echo "skip-worktree files: $(git ls-files -v | grep -c '^S')"

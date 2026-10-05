#!/usr/bin/env bash
# Marks rizzoo-generated theme outputs as skip-worktree so local
# regenerations (`rizzoo -i <img> -ro` via rofi-wallpaper.sh) stay
# machine-specific and `git status` stays clean.
#
# The baselines remain TRACKED, so fresh clones render immediately.
# Run once per fresh clone on the dynamic branch. The skip bit is
# index-local (not pushed); re-run it on every new machine.
#
# To undo (e.g. to commit a new baseline):
#   git update-index --no-skip-worktree -- <path>
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

git update-index --skip-worktree -- \
  "apps/bar/polybar/.config/polybar/colors/variants/dynamic.ini" \
  "apps/bar/waybar/.config/waybar/colors/variants/dynamic.css" \
  "apps/cli/btop/.config/btop/themes/dynamic.theme" \
  "apps/terminal/alacritty/.config/alacritty/colors/variants/dynamic.toml" \
  "apps/cli/starship/.config/starship/variants/dynamic.toml" \
  "apps/editor/zed/.config/zed/themes/dynamic.json" \
  "apps/launcher/rofi/.config/rofi/colors/variants/dynamic.rasi" \
  "apps/locker/hyprlock/.config/hypr/colors/variants/dynamic.conf" \
  "apps/locker/hyprlock/.config/hypr/wallpaper/variants/dynamic.conf" \
  "apps/terminal/ghostty/.config/ghostty/colors/variants/dynamic.ghostty" \
  "apps/wm/i3/.config/i3/colors/variants/dynamic.conf" \
  "apps/wm/sway/.config/sway/colors/variants/dynamic.conf" \
  "apps/terminal/kitty/.config/kitty/colors/variants/dynamic.conf" \
  "apps/cli/peaclock/.peaclock/variants/dynamic.conf" \
  "apps/wm/qtile/.config/qtile/colors/variants/dynamic.py" \
  "qt/qt5/.config/qt5ct/colors/dynamic.conf" \
  "qt/qt6/.config/qt6ct/colors/dynamic.conf" \
  "apps/capture/flameshot/.config/flameshot/variants/dynamic.ini" \
  "apps/editor/nvim/.config/nvim/lua/rizzoo/palette.lua" \
  "apps/wm/niri/.config/niri/kdl/layout.kdl" \
  "apps/tty/xresources/variants/dynamic" \
  "apps/notifier/dunst/.config/dunst/variants/dynamicrc" \
  "apps/cli/cava/.config/cava/config" \
  "apps/terminal/foot/.config/foot/color-foot.ini" \
  "noctalia-dell/.config/noctalia/palettes/rizzoo.json" \
  "noctalia-hp/.config/noctalia/palettes/rizzoo.json" \
  "qt/kvantum/.config/Kvantum/KvMaterial/KvMaterial.svg" \
  "qt/kvantum/.config/Kvantum/KvMaterial/KvMaterial.kvconfig"

echo "skip-worktree files: $(git ls-files -v | grep -c '^S')"

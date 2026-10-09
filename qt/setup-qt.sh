#!/usr/bin/env bash
set -euo pipefail

# arch-only. installs qt5ct qt6ct kvantum, links repo Kvantum config.
QT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGS="qt5ct qt6ct kvantum"

command -v pacman >/dev/null 2>&1 || { echo "Error: pacman not found. Arch assumed." >&2; exit 1; }

INSTALLER="sudo pacman -S --needed --noconfirm"

USE_YAY=false
if command -v yay >/dev/null 2>&1; then
  echo "Installer? (pacman recommended)"
  select _inst in pacman yay; do
    if [ "$_inst" = "yay" ]; then
      read -r -p "AUR might not be stable as you expect. Use yay anyway? [y/N] " _ans
      [ "$_ans" = "y" ] || [ "$_ans" = "Y" ] && USE_YAY=true || echo "Falling back to pacman."
    fi
    break
  done
fi
[ "$USE_YAY" = true ] && INSTALLER="yay -S --needed --noconfirm"

$INSTALLER $PKGS

SRC="$QT_ROOT/kvantum/.config/Kvantum"
DST="$HOME/.config/Kvantum"
if [ -e "$DST" ] && [ ! -L "$DST" ]; then
  mv "$DST" "$DST.bak" && echo "Backed up $DST to $DST.bak."
fi
mkdir -p "$HOME/.config"
ln -sfn "$SRC" "$DST"

[ "${QT_QPA_PLATFORMTHEME:-}" = "qt6ct" ] \
  || echo "Note: set QT_QPA_PLATFORMTHEME=qt6ct in WM autostart (sway/qtile already do)."

echo "Done: qt5ct qt6ct kvantum installed, Kvantum linked."

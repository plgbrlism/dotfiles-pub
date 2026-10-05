#!/usr/bin/env bash
set -euo pipefail

# arch-only. installs qt5ct qt6ct kvantum, links repo Kvantum config.
QT_ROOT="$HOME/dotfiles-pub/qt"
PKGS="qt5ct qt6ct kvantum"

command -v gum >/dev/null 2>&1 || { echo "Error: 'gum' not found. Install it first." >&2; exit 1; }
command -v pacman >/dev/null 2>&1 || { echo "Error: pacman not found. Arch assumed." >&2; exit 1; }

INSTALLER="sudo pacman -S --needed --noconfirm"

USE_YAY=false
if command -v yay >/dev/null 2>&1; then
  if [ "$(gum choose --header "Installer? (pacman recommended)" "pacman" "yay")" = "yay" ]; then
    gum confirm "AUR might not be stable as you expect; just choose pacman. Use yay anyway?" \
      && USE_YAY=true || echo "Falling back to pacman."
  fi
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

# link qt5ct/qt6ct conf + palettes too, else reruns never update them.
for v in "qt5:qt5ct" "qt6:qt6ct"; do
  src_base="$QT_ROOT/${v%%:*}/.config/${v##*:}"
  dst_base="$HOME/.config/${v##*:}"
  mkdir -p "$dst_base"
  for sub in "${v##*:}.conf" "colors"; do
    [ -e "$src_base/$sub" ] || continue
    if [ -e "$dst_base/$sub" ] && [ ! -L "$dst_base/$sub" ]; then
      mv "$dst_base/$sub" "$dst_base/$sub.bak" && echo "Backed up $dst_base/$sub."
    fi
    ln -sfn "$src_base/$sub" "$dst_base/$sub"
  done
done

[ "${QT_QPA_PLATFORMTHEME:-}" = "qt6ct" ] \
  || echo "Note: set QT_QPA_PLATFORMTHEME=qt6ct in WM autostart (sway/qtile already do)."

gum style --foreground 212 "Done: qt5ct qt6ct kvantum installed, Kvantum linked."

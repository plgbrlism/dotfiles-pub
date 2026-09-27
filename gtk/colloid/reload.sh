#!/usr/bin/env bash

# installer animation uses setterm, needs TERM in terminfo; no real tty here, so honest 'dumb'
export TERM="${TERM:-dumb}"

THEME_DIR=$(realpath "$HOME/dotfiles-pub/gtk/colloid/Colloid-gtk-theme")

cd "$THEME_DIR" || { echo "Error: Could not find theme folder at $THEME_DIR"; exit 1; }

rm -f "$HOME/.config/gtk-4.0/gtk.css"
./install.sh -d "$HOME/.themes" -c dark -s compact -l fixed --tweaks rimless black normal
rc=$?

systemctl --user restart xdg-desktop-portal-gtk

exit "$rc"

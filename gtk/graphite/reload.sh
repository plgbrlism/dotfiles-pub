#!/usr/bin/env bash

# installer animation uses setterm, needs TERM in terminfo; no real tty here, so honest 'dumb'
export TERM="${TERM:-dumb}"

THEME_DIR=$(realpath "$HOME/dotfiles-pub/gtk/graphite/Graphite-gtk-theme")

cd "$THEME_DIR" || { echo "Error: Could not find theme folder at $THEME_DIR"; exit 1; }

rm -f "$HOME/.config/gtk-4.0/gtk.css"
./parse-sass.sh
./install.sh -d "$HOME/.themes" -c dark -s compact -l --tweaks rimless normal darker --round 6px
rc=$?

systemctl --user restart xdg-desktop-portal-gtk

exit "$rc"

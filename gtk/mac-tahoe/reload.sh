#!/usr/bin/env bash

# installer animation uses setterm, needs TERM in terminfo; no real tty here, so honest 'dumb'
export TERM="${TERM:-dumb}"

THEME_DIR=$(realpath "$HOME/dotfiles-pub/gtk/mac-tahoe/MacTahoe-gtk-theme")

cd "$THEME_DIR" || { echo "Error: Could not find theme folder at $THEME_DIR"; exit 1; }

rm -f "$HOME/.config/gtk-4.0/gtk.css"
./parse-sass.sh
./install.sh -n Mac -d "$HOME/.themes" -c dark -o normal -l -f --darker
rc=$?

systemctl --user restart xdg-desktop-portal-gtk

exit "$rc"

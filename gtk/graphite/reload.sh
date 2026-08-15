#!/usr/bin/env bash

THEME_DIR=$(realpath "$HOME/dotfiles-pub/gtk/graphite/Graphite-gtk-theme")

cd "$THEME_DIR" || { echo "Error: Could not find theme folder at $THEME_DIR"; exit 1; }

rm -f "$HOME/.config/gtk-4.0/gtk.css"
./parse-sass.sh
./install.sh -d "$HOME/.themes" -c dark -s compact -l --tweaks rimless normal darker --round 6px

#!/usr/bin/env bash

THEME_DIR=$(realpath "$HOME/dotfiles-pub/gtk/mac-tahoe/MacTahoe-gtk-theme")

cd "$THEME_DIR" || { echo "Error: Could not find theme folder at $THEME_DIR"; exit 1; }

rm -f "$HOME/.config/gtk-4.0/gtk.css"
./parse-sass.sh
./install.sh -n Mac -d "$HOME/.themes" -c dark -o normal -l -f --darker 

#!/usr/bin/env bash

THEME_DIR=$(realpath "$HOME/dotfiles-pub/gtk/colloid/Colloid-gtk-theme")
#THEME_DIR=$(realpath "$HOME/source/Colloid-gtk-theme")

cd "$THEME_DIR" || { echo "Error: Could not find theme folder at $THEME_DIR"; exit 1; }

rm -f "$HOME/.config/gtk-4.0/gtk.css"
./install.sh -d "$HOME/.themes" -c dark -s compact -l fixed --tweaks rimless black normal

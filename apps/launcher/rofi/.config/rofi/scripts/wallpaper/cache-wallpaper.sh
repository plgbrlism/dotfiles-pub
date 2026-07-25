#!/usr/bin/env bash

# ~~ Cache files ~~
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
CACHE_FILE="${HOME}/.cache/wallpaper/current-wallpaper"

source "${SCRIPT_DIR}/setters/awww.sh"
source "${SCRIPT_DIR}/setters/swaybg.sh"
source "${SCRIPT_DIR}/setters/feh.sh"

restore() {
    if [ ! -f "$CACHE_FILE" ]; then
        echo "No cached wallpaper"
        exit 1
    fi
    
    wallpaper=$(cat "$CACHE_FILE")
    
    if [ ! -f "$wallpaper" ]; then
        echo "Cached wallpaper not found: $wallpaper"
        exit 1
    fi
    
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        if command -v awww >/dev/null 2>&1; then
            set_awww "$wallpaper"
        elif command -v swaybg >/dev/null 2>&1; then
            set_swaybg "$wallpaper"
        else
            echo "Error: No Wayland wallpaper setter found!"
            exit 1
        fi
    elif [ -n "${DISPLAY:-}" ]; then
        set_feh "$wallpaper"
    else
        echo "Error: Could not detect Wayland or X11."
        exit 1
    fi
    
    echo "Restored: $wallpaper"
}

if [ "${1:-}" = "--restore" ]; then
    restore
else
    if [ -f "$CACHE_FILE" ]; then
        cat "$CACHE_FILE"
    else
        echo "No cached wallpaper"
        exit 1
    fi
fi

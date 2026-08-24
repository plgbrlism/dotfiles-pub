#!/usr/bin/env bash

# /// TO-DO: add randomize image picker

# ~~ variables ~~
SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
CACHE_DIR="$HOME/.cache/wallpaper"
WALLPAPER_FILE_CACHE="$CACHE_DIR/current-wallpaper"
WALLPAPER_DIR_CACHE="$CACHE_DIR/current-wallpaper-dir"

STYLE="$HOME/.config/wofi/style.css"
STYLE_WIDE="$HOME/.config/wofi/style-wallpaper.css"

# ~~ Wallpaper Setters ~~
source "${SCRIPT_DIR}/setters/awww.sh"
source "${SCRIPT_DIR}/setters/swaybg.sh"
source "${SCRIPT_DIR}/setters/feh.sh"
source "$HOME/.config/wofi/scripts/wallpaper/setters/hrax.sh"

# ~~ helpers ~~
DIR_INIT="󱑾  add wallpaper directory"
CHANGE_DIR="change wallpaper directory"


mkdir -p "$CACHE_DIR"

# ~~ init (no wallpaper directory yet)
prompt_new_dir() {
	new_dir=$(wofi --dmenu \
		--style "$STYLE" \
		--prompt "󱑾  Path ->>" \
		--lines 1 \
		--define "dmenu-print_line_num=false" \
		--define "hide_search=false")

	if [ -z "$new_dir" ]; then
		exit 0
	fi

	new_dir="${new_dir/#\~/$HOME}"

	if [ -d "$new_dir" ]; then
		echo "$new_dir" > "$WALLPAPER_DIR_CACHE"
		exec "$0"
	else
		notify-send "Wallpaper Error" "Directory does not exist: $new_dir" -u critical
		exit 1
	fi
}


# ~~ detect active directory ~~
if [ -f "$WALLPAPER_DIR_CACHE" ]; then
	WALLPAPER_DIRECTORY="$(cat "$WALLPAPER_DIR_CACHE")"
else
	WALLPAPER_DIRECTORY=""
fi

# ~~ check proper images formats to display
wallpapers=()
if [ -n "$WALLPAPER_DIRECTORY" ] && [ -d "$WALLPAPER_DIRECTORY" ]; then
    while IFS= read -r -d '' file; do
        wallpapers+=("$file")
    done < <(find "$WALLPAPER_DIRECTORY" -maxdepth 1 -type f \( \
        -iname "*.jpg" -o \
        -iname "*.jpeg" -o \
        -iname "*.png" -o \
        -iname "*.gif" -o \
        -iname "*.bmp" -o \
        -iname "*.webp" \
    \) -print0 | sort -z)
fi

# ~~launch wofi with proper display
if [ ${#wallpapers[@]} -eq 0 ]; then
	wofi_format=$(printf "%s\n" "$DIR_INIT" | wofi --dmenu \
		--style "$STYLE" \
		--prompt "no wallpaper directory yet 󰯉 " \
		--lines 1 \
		--define "dmenu-print_line_num=false")

	if [ -z "$wofi_format" ]; then
		exit 0
	fi

	if [ "$wofi_format" = "$DIR_INIT" ]; then
	    prompt_new_dir
	fi

else
	wofi_list="${CHANGE_DIR}"

	for wallpaper in "${wallpapers[@]}"; do
		wofi_list="${wallpaper}\n${wofi_list}"
	done

	wofi_format=$(echo -en "$wofi_list" | wofi --dmenu \
		--style "$STYLE_WIDE" \
		--width 1200 \
		--prompt "Wallpaper" \
		--lines 1 \
		--columns 4 \
		--allow-images \
		--define "dmenu-print_line_num=false")

	if [ -z "$wofi_format" ]; then
		exit 0
	fi

	if [ "$wofi_format" = "$CHANGE_DIR" ]; then
        prompt_new_dir
    else
        selected="$wofi_format"
    fi
fi

if [ -z "$selected" ] || [ ! -f "$selected" ]; then
	exit 1
fi

# ~~ detect display servers
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    DISPLAY_SERVER="wayland"
elif [ -n "${DISPLAY:-}" ]; then
    DISPLAY_SERVER="x11"
else
    DISPLAY_SERVER="unknown"
fi

# ~~ apply wallpaper
case "$DISPLAY_SERVER" in
    "wayland")
        if command -v awww >/dev/null 2>&1; then
        	rizzoo -i "$selected" -ro &
            set_awww "$selected"
        elif command -v swaybg >/dev/null 2>&1; then
        	rizzoo -i "$selected" -ro &
            set_swaybg "$selected"
        else
            notify-send "Wallpaper Error" "No Wayland wallpaper setter found!" -u critical
            exit 1
        fi
        ;;
    "x11")
    	if command -v hrax >/dev/null 2>&1; then
    		rizzoo -i "$selected" -ro &
    		set_feh "$selected"
    	elif command -v feh >/dev/null 2>&1; then
    		rizzoo -i "$selected" -ro &
        	set_feh "$selected"
        else
            notify-send "Wallpaper Error" "No X11 supported wallpaper setter found" -u critical
            exit 1
        fi
        ;;
    *)
        notify-send "Wallpaper Error" "Could not detect Wayland or X11.\nDetected Server: $DISPLAY_SERVER" -u critical
        exit 1
        ;;
esac

# ~~ save cache ~~
echo "$selected" > "$WALLPAPER_FILE_CACHE"
exit 0

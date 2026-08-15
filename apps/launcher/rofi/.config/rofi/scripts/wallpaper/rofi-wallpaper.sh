#!/usr/bin/env bash

# /// TO-DO: add randomize image picker

# ~~ variables ~~
SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
CACHE_DIR="$HOME/.cache/wallpaper"
WALLPAPER_FILE_CACHE="$CACHE_DIR/current-wallpaper"
WALLPAPER_DIR_CACHE="$CACHE_DIR/current-wallpaper-dir"

THEME="$HOME/.config/rofi/config.rasi"

# ~~ Wallpaper Setters ~~
source "${SCRIPT_DIR}/setters/awww.sh"
source "${SCRIPT_DIR}/setters/swaybg.sh"
source "${SCRIPT_DIR}/setters/feh.sh"
source "$HOME/.config/rofi/scripts/wallpaper/setters/hrax.sh"

# ~~ helpers ~~
DIR_INIT="  add wallpaper directory"
CHANGE_DIR="  change wallpaper directory"


mkdir -p "$CACHE_DIR"

# ~~ init (no wallpaper directory yet)
prompt_new_dir() {
	new_dir=$(rofi -dmenu \
		-theme "$THEME" \
		-p "󱑾  Path ->" \
		-theme-str 'window { width: 600; }' \
		-theme-str 'entry { placeholder: "path/to/your/wallpapers..."; }' \
		-theme-str 'listview { enabled: false; }'
		)

	if [ -z "$new_dir" ]; then
		exit 0
	fi

	new_dir="${new_dir/#\~/$HOME}"

	if [ -d "$new_dir" ]; then
		echo "$new_dir" > "$WALLPAPER_DIR_CACHE"
		exec "$0"
	else
		rofi -e "Error: Directory does not exist: $new_dir" \
		-theme "$THEME"
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

# ~~launch rofi with proper display
if [ ${#wallpapers[@]} -eq 0 ]; then
	rofi_format=$(echo -en "${DIR_INIT}\n" | rofi -dmenu \
		-theme "$THEME" \
		-mesg "no wallpaper directory yet 󰯉 " \
		-theme-str 'window { width: 400; }' \
		-theme-str 'mainbox {children: [ message, listview ]; }' \
		-theme-str 'textbox { text-color: @muted; }' \
		-theme-str 'listview { columns: 1; lines: 1; }' \
		-theme-str 'element { children: [ element-text ]; }'
		)

	if [ -z "$rofi_format" ]; then
		exit 0
	fi

	if [ "$rofi_format" = "$DIR_INIT" ]; then
	    prompt_new_dir
	fi

else
	rofi_list="${CHANGE_DIR}\0icon\x1f${SCRIPT_DIR}/asset/change-wallpaper-directory.png\n"

	for wallpaper in "${wallpapers[@]}"; do
		rofi_list+="${wallpaper}\0icon\x1f${wallpaper}\n"
	done

	rofi_format=$(echo -en "$rofi_list" | rofi -dmenu \
		-theme "$THEME" \
		-show-icons \
		-theme-str 'mainbox {children: [ listview ]; }' \
		-theme-str 'listview { columns: 4; lines: 1; fixed-columns: true; fixed-height: true; }' \
		-theme-str 'window { width: 1200; }' \
		-theme-str 'element { children: [ element-icon ]; orientation: vertical; }' \
		-theme-str 'element-icon { size: 250; horizontal-align: 0.5; vertical-align: 0.5; }' \
		)

	if [ -z "$rofi_format" ]; then
		exit 0
	fi

	if [ "$rofi_format" = "$CHANGE_DIR" ]; then
        prompt_new_dir
    else
        selected="$rofi_format"
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
            set_awww "$selected"
            rizzoo -i "$selected" -ro
        elif command -v swaybg >/dev/null 2>&1; then
            set_swaybg "$selected"
            rizzoo -i "$selected" -ro
        else
            rofi -e "Error: No Wayland wallpaper setter found!" -theme "$THEME"
            exit 1
        fi
        ;;
    "x11")
    	if command -v hrax >/dev/null 2>&1; then
    		set_feh "$selected"
    		rizzoo -i "$selected" -ro
    	elif command -v feh >/dev/null 2>&1; then
        	set_feh "$selected"
        	rizzoo -i "$selected" -ro
        else
        	rofi -e "Error: No X11 supported wallpaper setter found" -theme "$THEME"
        	exit 1
        fi
        ;;
    *)
        rofi -e "Error: Could not detect Wayland or X11.
Detected Server: $DISPLAY_SERVER" -theme "$THEME"
        exit 1
        ;;
esac

# ~~ save cache ~~
echo "$selected" > "$WALLPAPER_FILE_CACHE"
exit 0

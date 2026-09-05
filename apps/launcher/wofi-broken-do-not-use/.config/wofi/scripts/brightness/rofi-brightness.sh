#!/usr/bin/env bash

# github: @plgbrlism
# tiktok: @fuzzbuzz.tech

# ~~ variables ~~
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
style="$HOME/.config/wofi/style.css"
BRIGHTNESS_SCRIPT="$HOME/.config/wofi/scripts/brightness/brightness-control.sh"
MIN_PERCENT=5
MAX_PERCENT=100

# ~~ icons ~~
ICON_BRIGHTNESS=" "
ICON_BRIGHTNESS_20="󰃛 "
ICON_BRIGHTNESS_40="󰃝 "
ICON_BRIGHTNESS_60="󰃞 "
ICON_BRIGHTNESS_80="󰃟 "
ICON_BRIGHTNESS_100="󰃠  "
ICON_UP="󰁅 "
ICON_DOWN="󰁆 "
ICON_SET="󱓡 "
ICON_INVALID=" "
ICON_CANCEL="󰜺 "

# ~~ get current brightness ~~
max=$(brightnessctl m)
current=$(brightnessctl g)
current_percent=$((current * 100 / max))

# ~~ status ~~
if [ "$current_percent" -le 20 ]; then
	MESG_STATUS="$ICON_BRIGHTNESS_20 Brightness: ${current_percent}%"
elif [ "$current_percent" -le 40 ]; then
	MESG_STATUS="$ICON_BRIGHTNESS_40 Brightness: ${current_percent}%"
elif [ "$current_percent" -le 60 ]; then
	MESG_STATUS="$ICON_BRIGHTNESS_60 Brightness: ${current_percent}%"
elif [ "$current_percent" -le 80 ]; then
	MESG_STATUS="$ICON_BRIGHTNESS_80 Brightness: ${current_percent}%"
elif [ "$current_percent" -le 100 ]; then
	MESG_STATUS="$ICON_BRIGHTNESS_100 Brightness: ${current_percent}%"
fi

# ~~ launch wofi ~~
new_percent=$(wofi --dmenu \
	--style "$style" \
    --prompt "$MESG_STATUS" \
    --lines 1 \
    --define "dmenu-print_line_num=false" \
    --define "hide_search=false")

# ~~ edge cases ~~
# if cancelled or submitted an empty input
if [[ -z "$new_percent" ]]; then
    exit 0
fi

# remove whitespace in input
new_percent=$(echo "$new_percent" | xargs)

# if input doesn't have valid number
if [[ ! "$new_percent" =~ [0-9] ]]; then
	notify-send "$ICON_BRIGHTNESS Invalid: Input a number (5-100)" -t 1500 -u critical
	exit 1
fi

# first valid number only from input
clean_input=$(echo "$new_percent" | grep -o '[0-9]*' | head -1 )

# check if clean_input has valid number
if [[ -z "$clean_input" ]]; then
	notify-send "$ICON_BRIGHTNESS Invalid: Input a number (5-100)" -t 1500 -u critical
	exit 1
fi

# check if clean_input is less than 5%
if [[ "$clean_input" -lt "$MIN_PERCENT" ]]; then
	notify-send "$ICON_BRIGHTNESS Too low: Minimum brightness is ${MIN_PERCENT}%" -t 1500 -u critical
	exit 1
fi

# check if clean_input is greater than 100%
if [[ "$clean_input" -gt "$MAX_PERCENT" ]]; then
	notify-send "$ICON_BRIGHTNESS Too high: Maximum brightness is ${MAX_PERCENT}%" -t 1500 -u critical
	exit 1
fi

# ~~ apply brightness ~~
$BRIGHTNESS_SCRIPT --set "$clean_input"

# 9. notification
if [ "$clean_input" -le 20 ]; then
	MESG_STATUS="$ICON_BRIGHTNESS_20 Brightness updated to: ${clean_input}"
elif [ "$clean_input" -le 40 ]; then
	MESG_STATUS="$ICON_BRIGHTNESS_40 Brightness updated to: ${clean_input}"
elif [ "$clean_input" -le 60 ]; then
	MESG_STATUS="$ICON_BRIGHTNESS_60 Brightness updated to: ${clean_input}"
elif [ "$clean_input" -le 80 ]; then
	MESG_STATUS="$ICON_BRIGHTNESS_80 Brightness updated to: ${clean_input}"
elif [ "$clean_input" -le 100 ]; then
	MESG_STATUS="$ICON_BRIGHTNESS_100 Brightness updated to: ${clean_input}"
fi
notify-send "$MESG_STATUS%" -t 1000 -r 9991

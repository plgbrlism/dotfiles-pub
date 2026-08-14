#!/usr/bin/env bash

# github: @plgbrlism
# tiktok: @sivops.tech

# ~~ variables ~~
theme="$HOME/.config/rofi/config.rasi"
scriptDirectory="$HOME/.config/rofi/scripts/"

options=(
	"  Session"
	"  Wi-Fi"
    "  Audio"
    "󰃟  Brightness"
   #"󰂯  Bluetooth"
    "  Wallpaper"
)

# ~~ launch rofi ~~
chosen=$(printf "%s\n" "${options[@]}" | rofi -dmenu \
	-format 'i' \
    -theme "${theme}" \
    -theme-str 'window { width: 250; }' \
    -theme-str 'mainbox { children: [ listview ]; }') #\
	#-theme-str 'listview { columns: 1; lines: 3; }')

[[ -z "$chosen" ]] && exit 0
selected="${options[$chosen]}"

# ~~ selections ~~
case "$selected" in
    *"Session"*)
        "${scriptDirectory}/session_manager/session_manager.sh"
        ;;
    *"Wi-Fi"*)
        "${scriptDirectory}/wifi/rofi-wifi.sh"
        ;;
    *"Audio"*)
        "${scriptDirectory}/audio/rofi-audio.sh"
        ;;
    *"Brightness"*)
        "${scriptDirectory}/brightness/rofi-brightness.sh"
        ;;
    #*"Bluetooth"*)
    #   "${scriptDirectory}/bluetooth/rofi-bluetooth.sh"
    #   ;;
    *"Wallpaper"*)
        "${scriptDirectory}/wallpaper/rofi-wallpaper.sh"
        ;;
esac

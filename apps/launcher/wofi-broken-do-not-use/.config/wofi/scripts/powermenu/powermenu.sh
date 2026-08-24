#!/usr/bin/env bash

# github: @plgbrlism
# tiktok: @fuzzbuzz.tech

# ~~ variables ~~
style="$HOME/.config/wofi/style-narrow.css"
scriptDirectory="$HOME/.config/wofi/scripts/"

options=(
	"  Session"
	"  Wi-Fi"
    "  Audio"
    "󰃟  Brightness"
   #"󰂯  Bluetooth"
    "  Wallpaper"
)

# ~~ launch wofi ~~
chosen=$(printf "%s\n" "${options[@]}" | wofi --dmenu \
    --style "$style" \
    --width 250 \
    --prompt "󰿨 " \
    --define "dmenu-print_line_num=true")

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

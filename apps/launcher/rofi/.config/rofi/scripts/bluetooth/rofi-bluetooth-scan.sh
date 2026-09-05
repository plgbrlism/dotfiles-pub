#!/usr/bin/env bash

# source global state variables from from generated cache
if [ -f /tmp/_rb_shared ]; then source /tmp/_rb_shared; else exit 1; fi

notify() {
    notify-send -u low -t 2500 "Bluetooth Scan" "$1"
}

if [ "$IS_ON" != true ]; then
    notify "Error: Controller is off!"
    exit 1
fi

notify "Scanning for new environments (5s)..."
timeout 5 bluetoothctl scan on > /dev/null 2>&1

# Read fresh device registers safely
mapfile -t DEVICES < <(bluetoothctl devices)

ICON_BACK="󱞳 "

options=()
options+=("$ICON_BACK Back")

for dev in "${DEVICES[@]}"; do
    if [[ -n "$dev" ]]; then
        mac=$(echo "$dev" | awk '{print $2}')
        name=$(echo "$dev" | cut -d' ' -f3-)
        options+=("$mac - $name")
    fi
done

chosen_idx=$(printf "%s\n" "${options[@]}" | rofi -dmenu \
	-theme "$theme" \
	-theme-str 'mainbox { children: [ listview ]; }' \
	-i -format 'i')

if [[ -z "$chosen_idx" ]] || [ "$chosen_idx" -eq 0 ]; then
    exec "$SCRIPT_DIR/rofi-bluetooth.sh"
fi

SELECTED="${options[$chosen_idx]}"
MAC=$(echo "$SELECTED" | awk '{print $1}')
NAME=$(echo "$SELECTED" | cut -d'-' -f2-)

if [ -n "$MAC" ]; then
    notify "Pairing with$NAME..."
    if bluetoothctl pair "$MAC" > /dev/null 2>&1 && \
       bluetoothctl trust "$MAC" > /dev/null 2>&1 && \
       bluetoothctl connect "$MAC"; then
        notify "Connected successfully!"
    else
        notify "Connection pairing failed."
    fi
    sleep 0.5; exec "$SCRIPT_DIR/rofi-bluetooth.sh"
fi

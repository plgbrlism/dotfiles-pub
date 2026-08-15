#!/bin/bash

# github: @plgbrlism
# tiktok: @fuzzbuzz.tech

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
theme="$HOME/.config/rofi/config.rasi"

notify() {
    notify-send "Bluetooth Manager" "$1" -u low -t 2000
}

# ~~ cache state vars ~~
_TMP_BT_SHOW="/tmp/_rb_show"
_TMP_BT_CONN="/tmp/_rb_conn"
_TMP_BT_DEVS="/tmp/_rb_devs"

bluetoothctl show > "$_TMP_BT_SHOW" &
bluetoothctl devices Connected > "$_TMP_BT_CONN" &
bluetoothctl devices > "$_TMP_BT_DEVS" &
wait

# ~~ states check from caches
if grep -q "Powered: yes" "$_TMP_BT_SHOW"; then
    IS_ON=true
    TOGGLE="  Turn Off"
else
    IS_ON=false
    TOGGLE="  Turn On"
fi

# ~~ write dynamic shared state configuration for sub-scripts
{
    printf 'IS_ON=%q\n'      "$IS_ON"
    printf 'theme=%q\n'      "$theme"
    printf 'SCRIPT_DIR=%q\n' "$SCRIPT_DIR"
} > /tmp/_rb_shared

# ~ send raw device maps directly to cache so sub-scripts do not need to requery them again
cat "$_TMP_BT_CONN" > /tmp/_rb_connected_list
cat "$_TMP_BT_DEVS" > /tmp/_rb_devices_list

# ~~ launch rofi ~~
options=()
options+=("$TOGGLE")

if [ "$IS_ON" = true ]; then
    # Format message block for Rofi showing connection count
    conn_count=$(wc -l < /tmp/_rb_connected_list)
    if [ "$conn_count" -gt 0 ]; then
        MESG_STATUS="󱚽  Active Connections: $conn_count"
        options+=("󰤮  Disconnect All")
    else
        MESG_STATUS="󱛅  Bluetooth Enabled (no connections)"
    fi

    options+=("  Scan & Connect")
    options+=("  Paired Devices")
else
    MESG_STATUS="󱛅  Bluetooth Disabled"
fi

# ~~ rofi main ~~
chosen_idx=$(printf "%s\n" "${options[@]}" | rofi -dmenu \
    -theme "$theme" \
    -theme-str "mainbox { children: [ message, listview ]; }" \
    -theme-str "listview { lines: 4; }" \
    -theme-str "window { width: 450; }" \
    -mesg "$MESG_STATUS" \
    -i \
    -format 'i' \
    -selected-row 0)


[[ -z "$chosen_idx" ]] && exit 0
selected="${options[$chosen_idx]}"

# ~~ edge cases ~~
case "$selected" in
    *"Turn On"*)
        notify "Powering adapter on..."
        bluetoothctl power on
        sleep 0.8; exec "$0"
        ;;
    *"Turn Off"*)
        notify "Powering adapter off..."
        bluetoothctl power off
        sleep 0.5; exec "$0"
        ;;
    *"Scan & Connect"*)
        exec "$SCRIPT_DIR/rofi-bluetooth-scan.sh"
        ;;
    *"Paired Devices"*)
        exec "$SCRIPT_DIR/rofi-bluetooth-paired.sh"
        ;;
    *"Disconnect All"*)
        notify "Disconnecting active links..."
        mapfile -t CONNECTED < <(awk '{print $2}' /tmp/_rb_connected_list)
        for mac in "${CONNECTED[@]}"; do
            bluetoothctl disconnect "$mac" &
        done
        wait
        notify "All devices dropped."
        sleep 0.5; exec "$0"
        ;;
esac

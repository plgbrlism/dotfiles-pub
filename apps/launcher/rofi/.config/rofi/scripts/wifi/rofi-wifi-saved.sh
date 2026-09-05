#!/usr/bin/env bash

#╭─────────────────────────────────────────────────────────────╮
#│ Saved Networks Sub-Menu                                     │
#│ Opened from rofi-wifi.sh → "Saved Networks →"              │
#╰─────────────────────────────────────────────────────────────╯

#╭─────────────────────────────────────────────────────────────╮
#│ Load Shared State Written by rofi-wifi.sh                   │
#╰─────────────────────────────────────────────────────────────╯
SHARED_STATE="/tmp/_rw_shared"
if [[ ! -f "$SHARED_STATE" ]]; then
    # Launched standalone — fetch state ourselves
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$HOME/.config/rofi/scripts/wifi/theme.sh"
    theme="$script/$style"
    current=$(nmcli -t -f NAME,TYPE connection show --active \
        | grep ":802-11-wireless" | cut -d: -f1 | head -1)
    current_uuid=$(nmcli -t -f NAME,UUID,TYPE connection show --active \
        | grep ":802-11-wireless" | cut -d: -f2 | head -1)
    MAX_RETRIES=3
    RETRY_DELAY=1
else
    source "$SHARED_STATE"
fi

wifi_list=$(cat /tmp/_rw_wifi_list 2>/dev/null || \
    nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list --rescan no 2>/dev/null)
wifi_list_ssids=$(cut -d: -f1 <<< "$wifi_list")

saved_connections=$(cat /tmp/_rw_saved 2>/dev/null || \
    nmcli -t -f NAME,TYPE connection show 2>/dev/null \
    | grep ":802-11-wireless" | cut -d: -f1 | sort -u)

#╭─────────────────────────────────────────────────────────────╮
#│ Icons                                                       │
#╰─────────────────────────────────────────────────────────────╯
ICON_SAVED="󱕣 "
ICON_SAVED_STAR="󰣙 "
ICON_CHECK=" "
ICON_SIGNAL_STRONG="󰤨 "
ICON_SIGNAL_GOOD="󰤥 "
ICON_SIGNAL_OK="󰤢 "
ICON_SIGNAL_WEAK="󰤟 "
ICON_SEPARATOR="────────────────────────────────"
ICON_BACK="󱞳 "

#╭─────────────────────────────────────────────────────────────╮
#│ Helpers                                                     │
#╰─────────────────────────────────────────────────────────────╯
get_signal_icon() {
    local signal=${1:-0}
    [[ "$signal" =~ ^[0-9]+$ ]] || signal=0
    if   (( signal >= 75 )); then echo "$ICON_SIGNAL_STRONG"
    elif (( signal >= 50 )); then echo "$ICON_SIGNAL_GOOD"
    elif (( signal >= 25 )); then echo "$ICON_SIGNAL_OK"
    else                          echo "$ICON_SIGNAL_WEAK"
    fi
}

connect_with_retry() {
    local ssid=$1 password=$2 retry=0
    while (( retry < MAX_RETRIES )); do
        if [[ -n "$password" ]]; then
            nmcli device wifi connect "$ssid" password "$password" 2>/dev/null
        else
            nmcli device wifi connect "$ssid" 2>/dev/null
        fi
        (( $? == 0 )) && return 0
        (( retry++ ))
        (( retry < MAX_RETRIES )) && {
            notify-send "Wi-Fi: Retrying $ssid ($retry/$MAX_RETRIES)..." -t 1000
            sleep "$RETRY_DELAY"
        }
    done
    return 1
}

#╭─────────────────────────────────────────────────────────────╮
#│ Build Menu                                                  │
#╰─────────────────────────────────────────────────────────────╯
options=()
declare -a ssid_map=()

options+=("$ICON_BACK Back")
ssid_map+=("")
# options+=("$ICON_SEPARATOR")
ssid_map+=("")

if [[ -z "$saved_connections" ]]; then
    options+=("  No saved networks found")
    ssid_map+=("")
else
    while IFS= read -r saved; do
        [[ -z "$saved" ]] && continue

        if grep -qxF "$saved" <<< "$wifi_list_ssids"; then
            local_signal=$(grep "^${saved}:" <<< "$wifi_list" | head -1 | cut -d: -f2)
            [[ "$local_signal" =~ ^[0-9]+$ ]] || local_signal=0
            sig_icon=$(get_signal_icon "$local_signal")
            signal_text="$sig_icon $local_signal%"
            in_range=" $ICON_CHECK"
        else
            signal_text="󰤭 not in range"
            in_range=""
        fi

        if [[ "$saved" == "$current" ]]; then
            options+=("$ICON_CHECK $ICON_SAVED_STAR $saved (active) $signal_text")
        else
            options+=("$ICON_SAVED $saved$in_range $signal_text")
        fi
        ssid_map+=("$saved")
    done <<< "$saved_connections"
fi

#╭─────────────────────────────────────────────────────────────╮
#│ Show Rofi                                                   │
#╰─────────────────────────────────────────────────────────────╯
chosen=$(printf "%s\n" "${options[@]}" | rofi -dmenu \
    -theme "$theme" \
    -i \
    -format 'i' \
    -selected-row 0 \
    -theme-str "window { width: 490; }" \
    -theme-str "mainbox { children: [ listview ]; }")

[[ -z "$chosen" ]] && exit 0
selected="${options[$chosen]}"
ssid="${ssid_map[$chosen]}"

#╭─────────────────────────────────────────────────────────────╮
#│ Handle Selection                                            │
#╰─────────────────────────────────────────────────────────────╯
case "$selected" in
    *"$ICON_BACK Back"*)
        exec "$SCRIPT_DIR/rofi-wifi.sh"
        ;;
    "$ICON_SEPARATOR"* | *"No saved"*)
        exit 0
        ;;
    *)
        [[ -z "$ssid" ]] && exit 0

        if [[ "$ssid" == "$current" ]]; then
            notify-send "Wi-Fi: Already connected to $ssid" -t 2000
            exit 0
        fi

        notify-send "Wi-Fi: Connecting to $ssid..." -t 2000
        connect_with_retry "$ssid"

        if (( $? == 0 )); then
            notify-send "Wi-Fi: Connected to $ssid" -t 3000 -i network-wireless-connected
            sleep 1
            exec "$SCRIPT_DIR/rofi-wifi.sh"
        else
            notify-send -u critical "Wi-Fi: Failed to connect to $ssid" \
                -t 3000 -i network-wireless-error
        fi
        ;;
esac

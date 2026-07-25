#!/bin/bash

# github: @plgbrlism
# tiktok: @sivops.tech

# ~~ variables ~~
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
theme="$HOME/.config/rofi/config.rasi"
CACHE_FILE="/tmp/wifi_scan_cache"
CACHE_TTL=5
MAX_RETRIES=3
RETRY_DELAY=1
_TMP_STATE="/tmp/_rw_state"
_TMP_CONN="/tmp/_rw_conn"
_TMP_ACTIVE="/tmp/_rw_active"
_TMP_WLIST="/tmp/_rw_wlist"

nmcli radio wifi > "$_TMP_STATE"  &
nmcli networking connectivity > "$_TMP_CONN"   &
nmcli -t -f NAME,UUID,TYPE connection show --active > "$_TMP_ACTIVE" &
nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan no \
 > "$_TMP_WLIST"  &
wait

wifi_state=$(< "$_TMP_STATE")
connectivity=$(< "$_TMP_CONN")

current=$(grep ":802-11-wireless" "$_TMP_ACTIVE" | cut -d: -f1 | head -1)
current_uuid=$(grep ":802-11-wireless" "$_TMP_ACTIVE" | cut -d: -f2 | head -1)
current_signal=$(grep "^\*" "$_TMP_WLIST" | cut -d: -f3 | head -1)
current_signal=${current_signal:-0}

# Strip IN-USE column → SSID:SIGNAL:SECURITY reused by sub-scripts
wifi_list=$(awk -F: '{OFS=":"; $1=""; sub(/^:/, ""); print}' "$_TMP_WLIST")
saved_connections=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null \
    | grep ":802-11-wireless" | cut -d: -f1 | sort -u)

#╭─────────────────────────────────────────────────────────────╮
#│ Write Shared State for Sub-Scripts                          │
#╰─────────────────────────────────────────────────────────────╯
{
    printf 'current=%q\n'        "$current"
    printf 'current_uuid=%q\n'   "$current_uuid"
    printf 'current_signal=%q\n' "$current_signal"
    printf 'wifi_state=%q\n'     "$wifi_state"
    printf 'theme=%q\n'          "$theme"
    printf 'MAX_RETRIES=%q\n'    "$MAX_RETRIES"
    printf 'RETRY_DELAY=%q\n'    "$RETRY_DELAY"
    printf 'SCRIPT_DIR=%q\n'     "$SCRIPT_DIR"
} > /tmp/_rw_shared

printf '%s' "$wifi_list"         > /tmp/_rw_wifi_list
printf '%s' "$saved_connections" > /tmp/_rw_saved

#╭─────────────────────────────────────────────────────────────╮
#│ Smart Scan                                                  │
#╰─────────────────────────────────────────────────────────────╯
smart_scan() {
    local force=${1:-false}
    if [[ "$force" == true ]]; then
        notify-send "Wi-Fi: Scanning for networks..." -t 1000
        nmcli dev wifi rescan 2>/dev/null
        touch "$CACHE_FILE"
        return
    fi
    if [[ -f "$CACHE_FILE" ]]; then
        local now cache_mtime
        now=$(date +%s)
        cache_mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
        (( now - cache_mtime < CACHE_TTL )) && return 0
    fi
    (nmcli dev wifi rescan 2>/dev/null && touch "$CACHE_FILE") &
}
smart_scan false

#╭─────────────────────────────────────────────────────────────╮
#│ Icons                                                       │
#╰─────────────────────────────────────────────────────────────╯
ICON_WIFI="󰤨 "
ICON_WIFI_ENABLED="󱚽 "
ICON_WIFI_DISABLED="󱛅 "
ICON_WIFI_ON=" "
ICON_WIFI_OFF=" "
ICON_DISCONNECT="󰤮 "
ICON_SCAN=" "
ICON_REFRESH="󰑓 "
ICON_SETTINGS="󰒓 "
# ICON_SEPARATOR="────────────────────────────────"
ICON_NAV=" "
ICON_FORGET="󰭙 "

#╭─────────────────────────────────────────────────────────────╮
#│ Build Main Menu                                             │
#╰─────────────────────────────────────────────────────────────╯
options=()

# if [[ "$wifi_state" == "enabled" ]]; then
#     if [[ -n "$current" ]]; then
#         options+=("$ICON_WIFI_ENABLED  Connected: $current [$current_signal%]")
#     else
#         options+=("$ICON_WIFI_ENABLED  Wifi Enabled: (No Connection)")
#     fi
# else
#     options+=("$ICON_WIFI_DISABLED  Wifi Disabled")
# fi

#╭─────────────────────────────────────────────────────────────╮
#│ Status Message Block for Rofi                               │
#╰─────────────────────────────────────────────────────────────╯
if [[ "$wifi_state" == "enabled" ]]; then
	if [[ -n "$current" ]]; then
		MESG_STATUS="$ICON_WIFI_ENABLED Connected to $current | $current_signal%"
	else
		MESG_STATUS="$ICON_WIFI_ENABLED Wi-Fi Enabled (not connected)"
	fi
else
	MESG_STATUS="$ICON_WIFI_DISABLED Wi-Fi Disabled"
fi



# options+=("$ICON_SEPARATOR")

if [[ "$wifi_state" == "enabled" ]]; then
    options+=("$ICON_WIFI_OFF  Off Wi-Fi")
else
    options+=("$ICON_WIFI_ON  On Wi-Fi")
fi

if [[ -n "$current" ]]; then
    options+=("$ICON_DISCONNECT  Disconnect ($current)")
    options+=("$ICON_FORGET  Forget Network ($current)")
fi

options+=("$ICON_SCAN  Scan")
# options+=("$ICON_REFRESH  Force full rescan")
# options+=("$ICON_SETTINGS  Open Network Settings")
# options+=("$ICON_SEPARATOR")
options+=("$ICON_NAV  Available Connections")
options+=("$ICON_NAV  Saved Connections")


#╭─────────────────────────────────────────────────────────────╮
#│ Show Rofi                                                   │
#╰─────────────────────────────────────────────────────────────╯
prompt_text="$ICON_WIFI"
[[ -n "$current" && "$current_signal" -gt 0 ]] && \
    prompt_text=" $prompt_text"

chosen=$(printf "%s\n" "${options[@]}" | rofi -dmenu \
    -theme "$theme" \
    -mesg "$MESG_STATUS" \
    -i \
    -format 'i' \
    -selected-row 0 \
    -theme-str 'mainbox { children: [ message, listview ]; }' \
    -theme-str 'listview { lines: 6; }' \
    -theme-str "window { width: 480px; }" )


[[ -z "$chosen" ]] && exit 0
selected="${options[$chosen]}"

#╭─────────────────────────────────────────────────────────────╮
#│ Handle Selection                                            │
#╰─────────────────────────────────────────────────────────────╯
case "$selected" in
    *"On Wi-Fi"*)
        nmcli radio wifi on
        notify-send "Wi-Fi: Wi-Fi enabled" -t 2000 -i network-wireless
        sleep 1; exec "$0"
        ;;
    *"Off Wi-Fi"*)
        nmcli radio wifi off
        notify-send "Wi-Fi: Wi-Fi disabled" -t 2000 -i network-wireless-disabled
        sleep 1; exec "$0"
        ;;
    *"Disconnect"*)
        [[ -z "$current" ]] && exit 0
        nmcli connection down id "$current" 2>/dev/null
        notify-send "Wi-Fi: Disconnected from $current" -t 2000
        sleep 1; exec "$0"
        ;;
    *"Forget Network"*)
        [[ -z "$current_uuid" ]] && exit 0
        if nmcli connection delete uuid "$current_uuid" 2>/dev/null; then
            notify-send "Wi-Fi: Forgot network: $current" -t 2000
        else
            notify-send -u critical "Wi-Fi: Failed to forget network" -t 2000
        fi
        sleep 1; exec "$0"
        ;;
    *"Scan"*)
        smart_scan true
        sleep 1; exec "$0"
        ;;
#    *"Open Network Settings"*)
#        if command -v nmtui &>/dev/null; then
#           ghostty -e nmtui &
#        else
#            notify-send "Wi-Fi" "No network settings GUI found" -t 2000
#        fi
#        ;;
    *"Available Connections"*)
        exec "$SCRIPT_DIR/rofi-wifi-available.sh"
        ;;
    *"Saved Connections"*)
        exec "$SCRIPT_DIR/rofi-wifi-saved.sh"
        ;;
esac

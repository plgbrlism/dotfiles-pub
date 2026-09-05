#!/usr/bin/env bash

#╭─────────────────────────────────────────────────────────────╮
#│ Available Networks Sub-Menu                                 │
#│ Opened from rofi-wifi.sh → "Available Networks"          │
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
ICON_CHECK=" "
ICON_LOCK="󰌾 "
ICON_UNLOCK="󰌿 "
ICON_SIGNAL_STRONG="󰤨 "
ICON_SIGNAL_GOOD="󰤥 "
ICON_SIGNAL_OK="󰤢 "
ICON_SIGNAL_WEAK="󰤟 "
ICON_SEPARATOR="────────────────────────────────"
ICON_BACK="󱞳 "
ICON_WARNING="󰀪 "
ICON_INFO="󰋼 "

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

get_security_icon() {
    case "$1" in
        WPA3*)       echo "󰌾" ;;
        WPA2*|WPA1*) echo "$ICON_LOCK" ;;
        WEP*)        echo "$ICON_UNLOCK" ;;
        --|-|"")     echo "󰖂" ;;
        *)           echo "$ICON_LOCK" ;;
    esac
}

quality_bar() {
    local q=${1:-0}
    [[ "$q" =~ ^[0-9]+$ ]] || q=0
    if   (( q >= 80 )); then echo "█"
    elif (( q >= 60 )); then echo "▓"
    elif (( q >= 40 )); then echo "▒"
    elif (( q >= 20 )); then echo "░"
    else                     echo " "
    fi
}

get_connection_quality() {
    local signal=${1:-0} security=$2
    [[ "$signal" =~ ^[0-9]+$ ]] || signal=0
    local score=$signal
    case "$security" in
        WEP*)    (( score -= 20 )) ;;
        --|-|"") (( score -= 10 )) ;;
    esac
    (( score < 0   )) && score=0
    (( score > 100 )) && score=100
    echo "$score"
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
declare -a security_map=()  # parallel array for security per entry

options+=("$ICON_BACK Back")
ssid_map+=(""); security_map+=("")
# options+=("$ICON_SEPARATOR")
ssid_map+=(""); security_map+=("")

network_count=0

# Sort by signal descending, skip blank/hidden SSIDs
while IFS=: read -r ssid signal security; do
    [[ -z "$ssid" || "$ssid" == "--" ]] && continue
    (( network_count++ ))

    [[ "$signal" =~ ^[0-9]+$ ]] || signal=0

    sig_icon=$(get_signal_icon "$signal")
    sec_icon=$(get_security_icon "$security")
    quality=$(get_connection_quality "$signal" "$security")
    qbar=$(quality_bar "$quality")

    is_saved=false
    grep -qxF "$ssid" <<< "$saved_connections" && is_saved=true
    saved_marker=""
    $is_saved && saved_marker="$ICON_SAVED"

    if [[ "$ssid" == "$current" ]]; then
        options+=("$ICON_CHECK $ssid $saved_marker $sig_icon $signal% $sec_icon $qbar (connected)")
    elif $is_saved; then
        options+=("$ICON_SAVED $ssid $sig_icon $signal% $sec_icon $qbar")
    else
        options+=("  $ssid $sig_icon $signal% $sec_icon $qbar")
    fi
    ssid_map+=("$ssid")
    security_map+=("$security")

done < <(sort -t: -k2 -rn <<< "$wifi_list" | grep -v '^--\|^:')

if (( network_count == 0 )); then
    options+=("  $ICON_WARNING No networks in range")
    ssid_map+=(""); security_map+=("")
    options+=("  $ICON_INFO Try moving closer to router")
    ssid_map+=(""); security_map+=("")
fi

#╭─────────────────────────────────────────────────────────────╮
#│ Show Rofi                                                   │
#╰─────────────────────────────────────────────────────────────╯
chosen=$(printf "%s\n" "${options[@]}" | rofi -dmenu \
    -theme "$theme" \
    -p " Available Networks" \
    -i \
    -format 'i' \
    -selected-row 0 \
    -theme-str "window { width: 580; }" \
    -theme-str "mainbox { children: [ listview ]; }")

[[ -z "$chosen" ]] && exit 0
selected="${options[$chosen]}"
ssid="${ssid_map[$chosen]}"
net_security="${security_map[$chosen]}"

#╭─────────────────────────────────────────────────────────────╮
#│ Handle Selection                                            │
#╰─────────────────────────────────────────────────────────────╯
case "$selected" in
    *"$ICON_BACK Back"*)
        exec "$SCRIPT_DIR/rofi-wifi.sh"
        ;;
    "$ICON_SEPARATOR"* | *"No networks"* | *"Try moving"*)
        exit 0
        ;;
    *"(connected)"*)
        # Already connected — do nothing
        exit 0
        ;;
    *)
        [[ -z "$ssid" ]] && exit 0

        # Saved network — connect directly (NM knows the password)
        if grep -qxF "$ssid" <<< "$saved_connections"; then
            notify-send "Wi-Fi: Connecting to saved network: $ssid" -t 2000
            connect_with_retry "$ssid"
        else
            # New network — prompt for password if secured
            if [[ -n "$net_security" && "$net_security" != "--" && "$net_security" != "-" ]]; then
                wifi_password=$(rofi -dmenu \
                    -theme "$theme" \
                    -p "󰌾 Password for $ssid:" \
                    -password)

                if [[ -z "$wifi_password" ]]; then
                    notify-send "Wi-Fi: Connection cancelled" -t 2000
                    exit 0
                fi

                notify-send "Wi-Fi: Connecting to $ssid..." -t 2000
                connect_with_retry "$ssid" "$wifi_password"
            else
                notify-send "Wi-Fi: Connecting to open network: $ssid..." -t 2000
                connect_with_retry "$ssid"
            fi
        fi

        if (( $? == 0 )); then
            notify-send "Wi-Fi:  Connected to $ssid" -t 3000 -i network-wireless-connected
            sleep 1
            exec "$SCRIPT_DIR/rofi-wifi.sh"
        else
            notify-send -u critical "Wi-Fi: Failed to connect to $ssid after $MAX_RETRIES attempts" \
                -t 3000 -i network-wireless-error
        fi
        ;;
esac

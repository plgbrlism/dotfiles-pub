#!/usr/bin/env bash

# github: @plgbrlism
# tiktok: @fuzzbuzz.tech

# ~~ VARIABLES  ~~
theme="$HOME/.config/rofi/config.rasi"
MIN_PERCENT=0
MAX_PERCENT=200


# ~~ ICONS ~~
ICON_VOLUME=" "
ICON_MUTED="󰝟 "
ICON_VOL_LOW="󰕿 "
ICON_VOL_MED="󰖀 "
ICON_VOL_HIGH="󰕾 "


# ~~ get current audio state ~~
current_percent=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | head -n1 | tr -d '%')
is_muted=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')


# ~~ Statuses ~~
if [ "$is_muted" = "yes" ] || [ "$current_percent" -eq 0 ]; then
    MESG_STATUS="$ICON_MUTED Volume: Muted"
elif [ "$current_percent" -le 33 ]; then
    MESG_STATUS="$ICON_VOL_LOW Volume: ${current_percent}%"
elif [ "$current_percent" -le 100 ]; then
    MESG_STATUS="$ICON_VOL_MED Volume: ${current_percent}%"
else
    MESG_STATUS="$ICON_VOL_HIGH Volume: ${current_percent}% (Amplified)"
fi

# ~~launch rofi ~~
user_input=$(rofi -dmenu \
    -theme "$theme" \
    -mesg "$MESG_STATUS" \
    -theme-str 'listview { lines: 1; }' \
    -theme-str "mainbox { children: [ entry, message, listview ]; }" \
    -theme-str "entry { placeholder: 'audio level | 0-200'; }")

# ~~ edge cases ~~
# if cancelled or submitted an empty input
if [[ -z "$user_input" ]]; then
    exit 0
fi

# cleans user input
clean_input=$(echo "$user_input" | xargs)

# if input doesn't have any number
if [[ ! "$clean_input" =~ [0-9] ]]; then
    notify-send "$ICON_VOLUME Invalid: Input a number (0-200)" -t 1500 -u critical
    exit 1
fi

# only first valid number from input
clean_input=$(echo "$clean_input" | grep -o '[0-9]*' | head -1)

# check if clean_input has valid number
if [[ -z "$clean_input" ]]; then
    notify-send "$ICON_VOLUME Invalid: Input a number (0-200)" -t 1500 -u critical
    exit 1
fi

# check if clean_input is greater than 200%
if [ "$clean_input" -gt "$MAX_PERCENT" ]; then
    notify-send "$ICON_VOLUME Limit: Maximum ceiling is ${MAX_PERCENT}%" -t 1500 -u critical
    exit 1
fi

# ~~ Update Audio Volume ~~

# if volume is 0 then mute
if [ "$clean_input" -eq 0 ]; then
    pactl set-sink-mute @DEFAULT_SINK@ true
    NOTIFY_MSG="$ICON_MUTED Volume: Muted"
else # unmute for valid numbers
    pactl set-sink-mute @DEFAULT_SINK@ false
    pactl set-sink-volume @DEFAULT_SINK@ "${clean_input}%"
    if [ "$clean_input" -le 33 ]; then
        NOTIFY_MSG="$ICON_VOL_LOW Volume updated to: ${clean_input}%"
    elif [ "$clean_input" -le 100 ]; then
        NOTIFY_MSG="$ICON_VOL_MED Volume updated to: ${clean_input}%"
    else
        NOTIFY_MSG="$ICON_VOL_HIGH Volume updated to: ${clean_input}% (Amplified)"
    fi
fi

notify-send "$NOTIFY_MSG" -t 1000 -r 9992

#!/bin/bash

# github: @plgbrlism
# tiktok: @fuzzbuzz.tech

# ~~ variables ~~
LOCKFILE="/tmp/brightness.lock"
MIN_PERCENT=5
STEP_PERCENT=5

# ~~ args ~~
MODE="down"
SET_VALUE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --up) MODE="up"; shift ;;
        --down) MODE="down"; shift ;;
        --set) MODE="set"; SET_VALUE="$2"; shift 2 ;;
        *) exit 1 ;;
    esac
done

# ~~ main
{
    # Try to acquire lock, exit if another instance is running
    flock -n 9 || exit 0

    # Get current brightness values
    current=$(brightnessctl g)
    max=$(brightnessctl m)

    # Calculate bounds
    min_value=$((max * MIN_PERCENT / 100))
    step_value=$((max * STEP_PERCENT / 100))

    # Calculate new value based on mode
    case $MODE in
        up)
            new_value=$((current + step_value))
            [ "$new_value" -gt "$max" ] && new_value="$max"
            ;;
        down)
            new_value=$((current - step_value))
            [ "$new_value" -lt "$min_value" ] && new_value="$min_value"
            ;;
        set)
            # SET_VALUE is percentage (e.g., 50 for 50%)
            new_value=$((max * SET_VALUE / 100))
            [ "$new_value" -lt "$min_value" ] && new_value="$min_value"
            [ "$new_value" -gt "$max" ] && new_value="$max"
            ;;
    esac

    brightnessctl set "$new_value"

} 9>"$LOCKFILE"

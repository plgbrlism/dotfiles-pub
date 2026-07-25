#!/bin/bash

# ~~ config
LOCKFILE="/tmp/brightness.lock"
MIN_PERCENT=5
STEP_PERCENT=5

# ~~ arguments
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

{
    flock -n 9 || exit 0
    
    current=$(brightnessctl g)
    max=$(brightnessctl m)
    
    min_value=$((max * MIN_PERCENT / 100))
    step_value=$((max * STEP_PERCENT / 100))
    
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
            new_value=$((max * SET_VALUE / 100))
            [ "$new_value" -lt "$min_value" ] && new_value="$min_value"
            [ "$new_value" -gt "$max" ] && new_value="$max"
            ;;
    esac
    
    brightnessctl set "$new_value"
    
} 9>"$LOCKFILE"

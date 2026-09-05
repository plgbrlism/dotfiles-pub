#!/usr/bin/env bash

killall -q waybar

while pgrep -u $UID -x waybar >/dev/null; do sleep 0.2; done

waybar &

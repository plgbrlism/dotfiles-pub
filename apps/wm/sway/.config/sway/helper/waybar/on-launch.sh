#!/usr/bin/env bash

killall -q waybar .waybar-wrapped

while pgrep -u $UID -x waybar >/dev/null; do sleep 0.2; done

waybar &

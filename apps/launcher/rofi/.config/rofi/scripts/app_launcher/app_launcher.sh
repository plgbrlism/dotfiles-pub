#!/usr/bin/env bash

# github: @plgbrlism
# tiktok: @fuzzbuzz.tech

theme="$HOME/.config/rofi/config.rasi"

rofi \
    -show drun \
    -theme ${theme} \
    -theme-str "configuration { show-icons: true; }" \
    -theme-str "inputbar { children: [ entry ]; }" \
	-theme-str "listview { lines: 6; }" \
	-theme-str 'entry { placeholder: "󰯉 ..."; }'

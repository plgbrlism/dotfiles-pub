#!/bin/bash

# github: @plgbrlism
# tiktok: @fuzzbuzz.tech

style="$HOME/.config/wofi/style.css"

wofi \
    --show drun \
    --style "$style" \
    --allow-images \
    --define "dmenu-parse_action=true" \
    --prompt "󰯉 "

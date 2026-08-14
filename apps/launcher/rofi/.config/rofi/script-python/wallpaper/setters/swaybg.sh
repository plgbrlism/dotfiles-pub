#!/usr/bin/env bash

# ~~ swaybg setter w/ proper handling ~~
set_swaybg() {
    local selected="$1"
    
    pkill swaybg 2>/dev/null || true
    nohup swaybg -i "$selected" -m fill >/dev/null 2>&1 &
    disown
}

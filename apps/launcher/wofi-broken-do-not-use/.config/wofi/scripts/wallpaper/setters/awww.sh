#!/usr/bin/env bash

# ~~ awww setter for wayland & w/ proper handling
set_awww() {
    local selected="$1"
    if ! pgrep -x "awww-daemon" > /dev/null; then
        awww-daemon --no-cache & disown
        sleep 0.5 # Give the daemon a half-second to wake up
    fi


    # freely change awww transtions from here ->>
    awww img "$selected" \
        --transition-type random
}

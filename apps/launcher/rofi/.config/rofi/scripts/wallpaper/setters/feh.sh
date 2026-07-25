#!/usr/bin/env bash

# ~~ feh setter for X11 environments ~~
set_feh() {
    local selected="$1"
    
    feh --bg-fill "$selected"
}

#!/usr/bin/env bash

# ~~ hrax setter (my own x11 native w/ animation) 
# for x11 environment ~~

set_hrax() {
	local selected="$1"

	hrax "$selected" -t grow -d 1200
}


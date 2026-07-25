#!/bin/sh

killall -q i3-qol

while pgrep -u $UID -x i3-qol >/dev/null; 
	do sleep 0.2; 
done

~/.local/bin/i3-qol autotiling &

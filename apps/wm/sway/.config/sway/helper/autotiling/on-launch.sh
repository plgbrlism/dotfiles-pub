#!/usr/bin/env bash

killall -q i3-qol

while pgrep -u $UID -x i3-qol >/dev/null;
	do sleep 0.2;
done

i3-qol autotiling -m master &

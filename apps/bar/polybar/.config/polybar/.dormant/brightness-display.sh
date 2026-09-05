#!/usr/bin/env bash
max=$(brightnessctl m)
current=$(brightnessctl g)
echo "$((100 * current / max))%"

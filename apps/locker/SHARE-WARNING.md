> Do not stow blindly.
Why: `wallpaper/wallpaper.conf` points to `~/.cache/wallpaper/current-wallpaper-image`,
a symlink maintained by the rofi wallpaper scripts. Run `rofi-wallpaper.sh` once
(or `cache-wallpaper.sh --restore`) to create it, or point to your own wallpaper path.

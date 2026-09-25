# ~~ applications ~

import os

HOME = os.path.expanduser("~")

TERMINAL = "kitty"
BROWSER = "firefox"
FILE_MANAGER = "nautilus"
TERMINAL_FM = "kitty -e yazi"
APP_LAUNCHER = f"{HOME}/.config/rofi/scripts/app_launcher/app_launcher.sh"
SESSION_MANAGER = f"{HOME}/.config/rofi/scripts/session_manager/session_manager.sh"
POWERMENU = f"{HOME}/.config/rofi/scripts/powermenu/powermenu.sh"
AUDIO_MENU = f"{HOME}/.config/rofi/scripts/audio/rofi-audio.sh"
BRIGHTNESS_MENU = f"{HOME}/.config/rofi/scripts/brightness/rofi-brightness.sh"
WIFI_MENU = f"{HOME}/.config/rofi/scripts/wifi/rofi-wifi.sh"
WALLPAPER_RESTORE = f"{HOME}/.config/rofi/scripts/wallpaper/cache-wallpaper.sh"
POLKIT_AGENT = "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1"

# ~~ autostart ~

import os
import configparser
import subprocess

from libqtile import hook
from libqtile.log_utils import logger

from conf.apps import POLKIT_AGENT, WALLPAPER_RESTORE

# services get system PATH only; prepend user dirs so scripts resolve
for _d in (
    f"{os.path.expanduser('~')}/.local/bin",
    f"{os.path.expanduser('~')}/scripts",
    f"{os.path.expanduser('~')}/.cargo/bin",
    f"{os.path.expanduser('~')}/.bun/bin",
):
    if _d not in os.environ.get("PATH", "").split(":"):
        os.environ["PATH"] = f"{_d}:{os.environ.get('PATH', '')}"

os.environ["XDG_CURRENT_DESKTOP"] = "qtile:gtk"

def _run(cmd):
    try:
        subprocess.Popen(cmd, shell=isinstance(cmd, str))
    except OSError:
        logger.exception("Failed to start: %s", cmd)

def get_active_theme():
    """Reads the active GTK theme dynamically, with a safe fallback."""
    try:
        config = configparser.ConfigParser()
        config.read(os.path.expanduser("~/.config/gtk-3.0/settings.ini"))
        return config["Settings"].get("gtk-theme-name", "Adwaita")
    except Exception:
        return "Adwaita"

active_theme = get_active_theme()
os.environ["QT_QPA_PLATFORMTHEME"] = "qt6ct"
os.environ.pop("QT_STYLE_OVERRIDE", None)

@hook.subscribe.startup_once
def autostart():
    _run(f"gsettings set org.gnome.desktop.interface gtk-theme '{active_theme}'")
    _run("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    # push session env to systemd/dbus before portals activate (no redirect: keep errors visible)
    _run(
        "dbus-update-activation-environment --systemd "
        "WAYLAND_DISPLAY DISPLAY PATH XDG_CURRENT_DESKTOP "
        "QT_QPA_PLATFORMTHEME"
    )
    _run("systemctl --user restart xdg-desktop-portal-gtk")
    _run(f"{WALLPAPER_RESTORE} --restore")
    _run("kanshi")
    # powertop needs sudo, or configure to run passwordless:
    _run("sudo /usr/sbin/powertop --auto-tune")
    # _run(POLKIT_AGENT)

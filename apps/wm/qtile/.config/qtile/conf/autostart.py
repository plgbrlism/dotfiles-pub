# ~~ autostart ~ ported from sway autostart.conf + system.conf (no dunst, no waybar) ~~

import os
import subprocess

from libqtile import hook

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


def _run(cmd):
    try:
        subprocess.Popen(cmd, shell=isinstance(cmd, str))
    except Exception:
        pass


@hook.subscribe.startup_once
def autostart():
    _run(
        "dbus-update-activation-environment --systemd "
        "WAYLAND_DISPLAY DISPLAY PATH XDG_CURRENT_DESKTOP=qtile"
    )
    _run("systemctl --user start xdg-desktop-portal-gtk")
    _run(POLKIT_AGENT)
    _run(f"{WALLPAPER_RESTORE} --restore")
    _run("kanshi")
    # ponytail: powertop needs sudo tty — run manually if wanted:
    # _run("sudo /usr/sbin/powertop --auto-tune")

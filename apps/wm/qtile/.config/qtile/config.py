#
#               ░██    ░██░██            
#               ░██       ░██            
#  ░████████ ░████████ ░██░██  ░███████  
# ░██    ░██    ░██    ░██░██ ░██    ░██ 
# ░██    ░██    ░██    ░██░██ ░█████████ 
# ░██   ░███    ░██    ░██░██ ░██        
#  ░█████░██     ░████ ░██░██  ░███████  
#        ░██                             
#        ░██                             
# 
# github: @plgbrlism
# tiktok: @fuzzbuzz.tech

from colors.colors import colors
from conf import system
from conf.autostart import autostart  # noqa: F401 — registers startup_once hook
from conf.groups import groups  # noqa: F401 — qtile reads module globals
from conf.keys import keys, mouse  # noqa: F401 — qtile reads module globals
from conf.layouts import (  # noqa: F401 — qtile reads module globals
    extension_defaults,
    floating_layout,
    layouts,
    widget_defaults,
)
from conf.screens import make_screen
from graphical_notifications import Notifier

# built-in notification daemon (replaces dunst)
notifier = Notifier(
    x=980,
    y=50,
    width=360,
    height=80,
    format="<b>{summary}</b>\n{body}",
    foreground=("#ffffff", colors["on_surface"], colors["on_error"]),
    background=(
        colors["surface_container_low"],
        colors["surface_container"],
        colors["error"],
    ),
    border=(colors["outline"], colors["primary"], colors["error"]),
    border_width=2,
    corner_radius=12,
    timeout=(4000, 5000, 0),
    font="JetBrainsMono Nerd Font SemiBold",
    fontsize=12,
    max_windows=3,
    gap=12,
)

# re-export system settings onto config module
wl_input_rules = system.wl_input_rules
wl_xcursor_theme = system.wl_xcursor_theme
wl_xcursor_size = system.wl_xcursor_size
follow_mouse_focus = system.follow_mouse_focus
bring_front_click = system.bring_front_click
floats_kept_above = system.floats_kept_above
cursor_warp = system.cursor_warp
auto_fullscreen = system.auto_fullscreen
focus_on_window_activation = system.focus_on_window_activation
focus_previous_on_window_remove = system.focus_previous_on_window_remove
reconfigure_screens = system.reconfigure_screens
screen_change_debounce_timeout = system.screen_change_debounce_timeout
auto_minimize = system.auto_minimize
dgroups_key_binder = system.dgroups_key_binder
dgroups_app_rules = system.dgroups_app_rules
wmname = system.wmname

screens = [make_screen()]

fake_screens = None

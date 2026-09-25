# ~~ system ~

from libqtile.backend.wayland import InputConfig

wl_input_rules = {
    "type:touchpad": InputConfig(
        tap=True,
        tap_button_map="lrm",
        dwt=True,
        drag_lock=False,
    ),
}

# resolution/position handled by kanshi (~/.config/kanshi/config)
# dual-monitor Screen↔Output mapping: generate_screens in conf/screens.py

wl_xcursor_theme = None
wl_xcursor_size = 24

follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
auto_fullscreen = True
focus_on_window_activation = "smart"
focus_previous_on_window_remove = False
reconfigure_screens = True
screen_change_debounce_timeout = 1
auto_minimize = True
dgroups_key_binder = None
dgroups_app_rules = []
wmname = "LG3D"

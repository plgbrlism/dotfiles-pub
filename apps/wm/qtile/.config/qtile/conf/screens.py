# ~~ screens + bar ~ Cozytile curves + waybar pills colors, Nerd Fonts only ~~

from colors.colors import colors
from libqtile import bar
from libqtile.config import Screen
from libqtile.lazy import lazy
from qtile_extras import widget
from qtile_extras.widget.decorations import PowerLineDecoration, RectDecoration

from conf import apps

# bar window itself transparent; end widgets carve the 4/12/4/12 silhouette
TRANSPARENT = "#00000000"

# ponytail: S-curve is a polyline approx of Cozytile 5.png/6.png; add points if janky
S_LEFT = [(0, 0), (0.6, 0.2), (0.3, 0.5), (0.6, 0.8), (0, 1)]
S_RIGHT = [(1, 0), (0.4, 0.2), (0.7, 0.5), (0.4, 0.8), (1, 1)]


def seg(bg, path=None, end=None):
    """Full-bleed Cozytile segment. Ends split the bar's 4/12/4/12 radius."""
    radius = 0
    if end == "left":
        radius = [6, 0, 0, 12]
    elif end == "right":
        radius = [0, 12, 4, 0]
    decos = [
        RectDecoration(
            use_widget_background=True, filled=True, radius=radius, padding_y=0
        )
    ]
    if path is not None:
        decos.append(PowerLineDecoration(path=path, size=15, padding_y=0))
    return {"decorations": decos, "padding": 8, "background": bg}


def slash(bg, path):
    # transition shape between segments; Rect+PowerLine can't share a widget:
    # PowerLine repaints a square bg that would erase rounded corners
    return {
        "decorations": [PowerLineDecoration(path=path, size=15, padding_y=0)],
        "padding": 0,
        "background": bg,
    }


def bar_widgets():
    return [
        widget.TextBox(
            text=" \U000f0d72 ",
            fontsize=18,
            name="powermenu",
            foreground=colors["on_primary"],
            mouse_callbacks={"Button1": lazy.spawn(apps.POWERMENU)},
            **seg(colors["primary"], end="left"),
        ),
        widget.TextBox(
            text=" ",
            foreground=colors["on_primary"],
            **slash(colors["primary"], path="forward_slash"),
        ),
        widget.GroupBox(
            font="JetBrainsMono Nerd Font SemiBold",
            fontsize=18,
            highlight_method="block",
            rounded=True,
            active=colors["primary"],
            inactive=colors["surface_bright"],
            block_highlight_text_color=colors["primary"],
            highlight_color=colors["primary"],
            this_current_screen_border=colors["surface_container_low"],
            this_screen_border=colors["secondary"],
            other_current_screen_border=colors["secondary"],
            other_screen_border=colors["surface_container_high"],
            urgent_border=colors["error"],
            urgent_text=colors["on_error"],
            foreground=colors["surface_bright"],
            disable_drag=True,
            hide_unused=False,
            spacing=4,
            borderwidth=3,
            margin_y=0,
            padding_x=4,
            **seg(colors["surface_container_low"], path="rounded_right"),
        ),
        widget.WindowName(
            max_chars=130,
            empty_group_string="Desktop",
            font="JetBrainsMono Nerd Font SemiBold",
            fontsize=13,
            foreground=colors["on_secondary"],
            **seg(colors["secondary"], path="rounded_right"),
        ),
        widget.Spacer(length=bar.STRETCH, background=colors["background"]),
        widget.StatusNotifier(
            icon_size=15,
            foreground=colors["on_secondary"],
            **seg(colors["secondary"], path=S_LEFT),
        ),
        widget.Volume(
            unmute_format="\U000f057e {volume}%",
            mute_format="\U000f038a muted",
            get_volume_command="pactl get-sink-volume @DEFAULT_SINK@",
            check_mute_command="pactl get-sink-mute @DEFAULT_SINK@",
            check_mute_string="yes",
            volume_up_command="pactl set-sink-volume @DEFAULT_SINK@ +5%",
            volume_down_command="pactl set-sink-volume @DEFAULT_SINK@ -5%",
            mute_command="pactl set-sink-mute @DEFAULT_SINK@ toggle",
            mute_foreground=colors["on_error"],
            foreground=colors["on_primary"],
            update_interval=0.5,
            mouse_callbacks={"Button1": lazy.spawn(apps.AUDIO_MENU)},
            **seg(colors["primary"], path="back_slash"),
        ),
        widget.Backlight(
            format="\U000f00e0 {percent:2.0%}",
            backlight_name="intel_backlight",
            change_command="brightnessctl set {0}%",
            foreground=colors["on_secondary"],
            mouse_callbacks={
                "Button1": lazy.spawn(apps.BRIGHTNESS_MENU),
            },
            **seg(colors["secondary"], path="rounded_right"),
        ),
        widget.WlanIw(
            interface="wlan0",
            format="\U000f0928 {essid}",
            disconnected_message="\U000f092d no Internet",
            foreground=colors["on_primary"],
            mouse_callbacks={"Button1": lazy.spawn(apps.WIFI_MENU)},
            update_interval=5,
            **seg(colors["primary"], path="forward_slash"),
        ),
        widget.Battery(
            battery="BAT0",
            format="{char} {percent:2.0%}",
            charge_char="\U000f0083",
            discharge_char="\U000f0079",
            full_char="\U000f0079",
            unknown_char="\U000f0091",
            empty_char="\U000f008e",
            not_charging_char="\U000f0079",
            foreground=colors["on_secondary"],
            low_percentage=0.30,
            low_foreground=colors["error"],
            charging_foreground=colors["tertiary"],
            show_short_text=False,
            update_interval=5,
            **seg(colors["secondary"], path=S_RIGHT),
        ),
        widget.CPU(
            format="\U000f07af CPU {load_percent}%",
            foreground=colors["on_primary"],
            update_interval=5,
            **seg(colors["primary"], end="right"),
        ),
    ]


def make_bar():
    return bar.Bar(
        bar_widgets(),
        25,
        background=TRANSPARENT,
        margin=[4,80,4,80],
        border_width=0,
    )


def make_screen():
    return Screen(top=make_bar(), background=colors["background"])


def generate_screens(outputs):
    """Same bar on every connected output (waybar parity)."""
    return [make_screen() for _ in outputs]

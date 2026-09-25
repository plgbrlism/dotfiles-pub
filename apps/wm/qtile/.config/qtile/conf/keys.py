# ~~ keys ~

from libqtile.config import Click, Drag, Key
from libqtile.lazy import lazy

from conf.apps import (
    APP_LAUNCHER,
    AUDIO_MENU,
    BRIGHTNESS_MENU,
    BROWSER,
    FILE_MANAGER,
    POWERMENU,
    SESSION_MANAGER,
    TERMINAL,
    TERMINAL_FM,
    WIFI_MENU,
)

mod = "mod4"
alt = "mod1"



keys = [
    # Core Actions
    Key([mod], "Return", lazy.spawn(TERMINAL), desc="terminal"),
    Key([mod], "e", lazy.spawn(FILE_MANAGER), desc="file manager"),
    Key([mod], "y", lazy.spawn(TERMINAL_FM), desc="terminal file manager"),
    Key([mod], "c", lazy.window.kill(), desc="kill"),
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="fullscreen"),
    Key([mod], "v", lazy.window.toggle_floating(), desc="float"),
    Key([mod], "r", lazy.spawn(APP_LAUNCHER), desc="app launcher"),
    Key([mod], "Escape", lazy.spawn(SESSION_MANAGER), desc="session manager"),
    Key([mod], "Space", lazy.spawn(POWERMENU), desc="powermenu"),
    Key([mod], "m", lazy.shutdown(), desc="exit qtile"),
    Key([mod, "shift"], "e", lazy.reload_config(), desc="reload"),
    Key([mod, "shift"], "r", lazy.restart(), desc="restart"),
    # Browser
    Key([mod], "b", lazy.spawn(BROWSER), desc="browser"),
    # Focus (hjkl)
    Key([mod], "h", lazy.layout.left(), desc="focus left"),
    Key([mod], "l", lazy.layout.right(), desc="focus right"),
    Key([mod], "k", lazy.layout.up(), desc="focus up"),
    Key([mod], "j", lazy.layout.down(), desc="focus down"),
    # Move windows
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="move left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="move right"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="move up"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="move down"),
    Key([mod, "shift"], "Left", lazy.layout.shuffle_left(), desc="move left"),
    Key([mod, "shift"], "Right", lazy.layout.shuffle_right(), desc="move right"),
    Key([mod, "shift"], "Up", lazy.layout.shuffle_up(), desc="move up"),
    Key([mod, "shift"], "Down", lazy.layout.shuffle_down(), desc="move down"),
    # Resize
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="grow height"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="shrink height"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="grow width"),
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="shrink width"),
    Key([mod], "n", lazy.layout.normalize(), desc="normalize"),
    Key([mod], "Tab", lazy.next_layout(), desc="next layout"),
    # Screen / group cyclings
    Key([alt], "Tab", lazy.screen.next_group(), desc="next group"),
    Key([alt, "shift"], "Tab", lazy.screen.prev_group(), desc="prev group"),
    # Scratchpad
    Key([mod, "shift"], "minus", lazy.window.togroup("scratchpad"), desc="move to scratchpad"),
    Key([mod], "minus", lazy.group["scratchpad"].dropdown_toggle("term"), desc="scratchpad show"),
    # Bar widget click targets reusable via spawn
    Key([mod, "control"], "a", lazy.spawn(AUDIO_MENU)),
    Key([mod, "control"], "b", lazy.spawn(BRIGHTNESS_MENU)),
    Key([mod, "control"], "w", lazy.spawn(WIFI_MENU)),
]

# Workspaces 1-10 (key 0 → group 10, like sway)
for i in range(1, 11):
    name = str(i)
    key = "0" if i == 10 else name
    keys.extend(
        [
            Key([mod], key, lazy.group[name].toscreen(), desc=f"group {name}"),
            Key(
                [mod, "shift"],
                key,
                lazy.window.togroup(name, switch_group=True),
                desc=f"move to {name}",
            ),
        ]
    )

# Wayland VT switch
from libqtile import qtile

for vt in range(1, 8):
    keys.append(
        Key(
            ["control", alt],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"VT{vt}",
        )
    )

mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

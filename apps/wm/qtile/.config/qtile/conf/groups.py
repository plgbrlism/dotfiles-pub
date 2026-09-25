# ~~ groups ~

from libqtile import hook, qtile
from libqtile.config import DropDown, Group, ScratchPad

# waybar parity: snowflake everywhere, fire on focused (configs/1.jsonc format-icons)
DEFAULT_ICON = ""
FOCUSED_ICON = ""

groups = [Group(str(i), label=DEFAULT_ICON) for i in range(1, 11)]

groups.append(
    ScratchPad(
        "scratchpad",
        [
            DropDown(
                "term",
                "kitty",
                x=0.05,
                y=0.05,
                width=0.90,
                height=0.40,
                opacity=0.95,
                on_focus_lost_hide=True,
            ),
        ],
    )
)


def _refresh_labels():
    for g in qtile.groups:
        if not g.name.isdigit():
            continue
        g.label = FOCUSED_ICON if g is qtile.current_group else DEFAULT_ICON
    for screen in qtile.screens:
        if screen.top:
            screen.top.draw()


@hook.subscribe.startup_complete
@hook.subscribe.setgroup
def _workspace_icons(*args):
    _refresh_labels()

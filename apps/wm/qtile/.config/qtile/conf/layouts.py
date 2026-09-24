# ~~ layouts ~ sway appearance.conf + colors + qtile-extras RoundedCorners ~~

from colors.colors import colors
from libqtile import layout
from libqtile.config import Match
from qtile_extras.layout.decorations import RoundedCorners

MARGIN = 3
BORDER_WIDTH = 4  # ponytail: radius = bw/2 → 2px round; raise for swayfx-like

layouts = [
    layout.Columns(
        border_focus=RoundedCorners(colour=colors["focused"]),
        border_unfocused=RoundedCorners(colour=colors["focused_inactive"]),
        border_width=BORDER_WIDTH,
        margin=MARGIN,
        insert_position=1,
    ),
    layout.Max(),
]

floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),
        Match(wm_class="makebranch"),
        Match(wm_class="maketag"),
        Match(wm_class="ssh-askpass"),
        Match(title="branchdialog"),
        Match(title="pinentry"),
        Match(wm_class="pavucontrol"),
        Match(wm_class="blueman-manager"),
    ],
    border_focus=RoundedCorners(colour=colors["focused"]),
    border_width=BORDER_WIDTH,
)

widget_defaults = dict(
    font="JetBrainsMono Nerd Font SemiBold",
    fontsize=13,
    padding=0,
)
extension_defaults = widget_defaults.copy()

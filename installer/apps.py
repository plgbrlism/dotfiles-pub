"""Package table ported from the old install.sh APPS list.

Row format kept identical to the bash table:
cat|dir|pacman pkgs|aur pkgs|bin|stow-ignore
"""
from dataclasses import dataclass, field


@dataclass
class App:
    cat: str
    name: str
    pacman: list[str] = field(default_factory=list)
    aur: list[str] = field(default_factory=list)
    bin: str = ""
    ignore: str = ""


def _row(line: str) -> App:
    parts = line.split("|")
    parts += [""] * (6 - len(parts))
    cat, name, pac, aur, bin_, ignore = parts[:6]
    return App(
        cat=cat,
        name=name,
        pacman=pac.split(),
        aur=aur.split(),
        bin=bin_,
        ignore=ignore,
    )


_ROWS = """\
cli|btop|btop||btop|
cli|cava|cava||cava|
cli|fastfetch|fastfetch||fastfetch|
cli|glow|glow||glow|
cli|lavat||lavat-git|lavat|
cli|peaclock||peaclock|peaclock|history
cli|rizzoo|||rizzoo|
cli|starship|starship||starship|
cli|yazi|yazi||yazi|
editor|micro|micro||micro|
editor|nvim|neovim||nvim|
editor|zed|zed||zed|
 service|xdg-desktop-portal|xdg-desktop-portal-wlr xdg-desktop-portal-gtk|||
 qt|qt5ct|qt5ct||qt5ct|
 qt|qt6ct|qt6ct||qt6ct|
 qt|kvantum|kvantum kvantum-qt5||kvantum|
terminal|alacritty|alacritty||alacritty|
terminal|foot|foot||foot|
terminal|ghostty|ghostty||ghostty|
terminal|kitty|kitty||kitty|
utils|kanshi|kanshi||kanshi|
wm|dispatcher||||dispatch|
wm|niri||niri-git|niri|
wm|sway|swaybg swaylock|swayfx|sway|
tty|xresources||||
"""

APPS: list[App] = [_row(l) for l in _ROWS.splitlines() if l.strip()]

CATEGORIES = [
    "cli", "editor", "service",
    "terminal", "tty", "utils", "wm", "noctalia", "gtk", "qt",
    "base", "fonts", "audio", "browsers", "media", "desktop", "tools",
]

# categories handled specially, not via stow_app
SPECIAL_CATS = {"noctalia", "gtk", "qt", "tty"}

# install-only categories: package groups with no configs to stow
# (subset of pacman/aur_pkgs.txt; expand when someone misses a pkg).
INSTALL_CATS = {"base", "fonts", "audio", "browsers", "media", "desktop", "tools"}


# System package groups, picked like any other category (no stow involved).
CAT_PKGS: dict[str, dict[str, list[str]]] = {
    "base": {"pacman": ["git", "stow", "base-devel", "fzf", "fd", "bat", "tldr", "zoxide", "tmux",
                         "zsh-autosuggestions", "zsh-syntax-highlighting"],
             "aur": ["yay-bin"]},
    "fonts": {"pacman": ["noto-fonts", "noto-fonts-emoji", "ttf-firacode-nerd",
                         "ttf-jetbrains-mono-nerd", "ttf-liberation", "ttf-dejavu"],
              "aur": ["otf-departure-mono-nerd", "ttf-ms-fonts", "ttf-unifont", "siji-ttf"]},
    "audio": {"pacman": ["pipewire", "pipewire-alsa", "pipewire-jack", "pipewire-pulse",
                         "wireplumber", "pavucontrol"],
              "aur": []},
    "browsers": {"pacman": ["firefox"], "aur": ["brave-origin-bin", "google-chrome", "zen-browser-bin"]},
    "media": {"pacman": ["mpv", "vlc", "imv", "feh", "inkscape", "krita", "obs-studio", "peek",
                         "gpu-screen-recorder", "grim", "wl-clipboard", "gst-plugin-pipewire",
                         "ffmpegthumbnailer", "poppler", "tumbler", "xwallpaper", "imagemagick"],
              "aur": ["gpu-screen-recorder-gtk"]},
    "desktop": {"pacman": ["bitwarden", "anki", "nautilus", "lxappearance", "nwg-look", "xss-lock"],
                "aur": ["vesktop-bin", "onlyoffice-bin", "unityhub", "cursor-appimage", "megacmd",
                        "clyp-bin", "universal-android-debloater-bin", "aura-git", "veila-git", "wbg",
                        "i3lock-color", "i3lock-fancy-rapid-git"]},
    "tools": {"pacman": ["lazygit", "atuin", "just", "jq", "tree", "rsync", "wget", "dust", "pastel",
                         "xclip", "autorandr", "brightnessctl", "bluetui", "bluez", "bluez-utils",
                         "tlp", "powertop", "fwupd", "pacman-contrib", "systemctl-tui", "smartmontools",
                         "lsof", "vhs", "awww", "cowsay", "figlet", "cmatrix", "7zip", "unzip"],
              "aur": []},
}


def apps_in(cat: str) -> list[App]:
    return [a for a in APPS if a.cat == cat]

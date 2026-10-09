# Paul's dotfiles

Arch-first dotfiles, made for me, usable by others. Configs live here as
plain files. `stow` symlinks them into your home folder. If you dislike a
config, do not stow it.

## Prereqs

Arch with `pacman`, or NixOS with `nixos-rebuild`. Nix configs live in `nix/`.
You need `python`, `git`, `stow`, and `sudo`.

```sh
# Arch
sudo pacman -S --needed python git stow
```

`yay` is optional. The installer builds it when an AUR package needs it.

`install.sh` builds `.venv` on first run with `rich` and `questionary`, using
`uv` when present and `python -m venv` otherwise. On NixOS the launcher pulls
`python3` from `nix-shell`, since the system has none.

## Install

```sh
git clone https://github.com/plgbrlism/dotfiles-pub ~/dotfiles-pub
cd ~/dotfiles-pub
./install.sh
```

## Menu

Type a number, press enter. Every entry returns to the menu when it finishes.

1. **full install**: preflight, then pick apps and install-only groups with
   arrow keys, review the missing packages, confirm. Then packages, stow,
   hooks, themes, theme bits, and validation, in that order.
2. **packages**: install everything the manifests list that is missing.
   Nothing else changes.
3. **stow**: link the recorded picks into home. Installs nothing.
4. **hooks**: write `.installer/hooks/` and point `core.hooksPath` at it.
5. **themes**: run `gtk/setup-gtk.sh` and `qt/setup-qt.sh`.
6. **theme bits**: reapply the skip-worktree marks. `dynamic` only.
7. **validate**: check packages, symlinks, hooks, binaries, and theme bits.
   Changes nothing.
8. **update**: `git pull`, replay the picks from the last full install,
   revalidate.
9. **rebuild nixos**: `nixos-rebuild switch`. Only on NixOS.

The install-only groups hold packages with no config to stow: `base`,
`fonts`, `audio`, `browsers`, `media`, `desktop`, `tools`. Kernel, boot, and
drivers are install-time system layer, out of scope here. Apps flagged
`.no-share` are machine-specific: the installer prints their warning file and
skips them, so nothing lands in `~` by surprise.

Every step also runs headless by name, which suits scripts and keybindings:

```sh
./install.sh validate
./install.sh theme-bits
```

Picks live in `~/.local/state/dotfiles/picks.txt`. `packages`, `stow`, and
`update` replay them, and say so when nothing is recorded yet.

## Packages

`.installer/manifests/` holds the only package names in this repo. Nothing is
hardcoded in the code.

- `apps.txt`: `cat|name|pacman|aur|binary to verify|stow ignore regex`. One
  row per stow package. A name of `@dir` stows all of `apps/dir` as a single
  unit, for categories whose subdirs are not separate packages. `gtk` and `qt`
  rows name top-level setup dirs instead, so they get a setup script rather
  than a stow.
- `groups.txt`: `group|pacman|aur` for the install-only groups above.

Missing packages come from one cached `pacman -Q` per package, then install
missing-only through `pacman -S --needed`.

## Conflicts

Stow descends into directories that already exist, so a shared `~/.config` is
linked one level down rather than replaced. Only real *files* that block a
link move aside as `.bak`. Nothing is deleted.

## Branches

`master` pins the calamus colorscheme. `dynamic` tracks rizzoo-generated
`dynamic.*` baselines and re-marks them skip-worktree on checkout, so local
regenerations stay machine-specific and `git status` stays clean.

## Folders

```
dotfiles-pub/
├── apps/          one folder per app, each holding its real config
│   ├── bar/       polybar, waybar
│   ├── capture/   flameshot
│   ├── cli/       btop, cava, fastfetch, glow, lavat, peaclock, rizzoo,
│   │              starship, yazi
│   ├── compositor/picom
│   ├── editor/    micro, nvim, zed
│   ├── file/      xarchiver
│   ├── launcher/  rofi
│   ├── locker/    hyprlock
│   ├── note/      obsidian
│   ├── notifier/  dunst
│   ├── service/   xdg-desktop-portal
│   ├── shell/     zsh
│   ├── terminal/  alacritty, foot, ghostty, kitty
│   ├── tty/       xresources
│   ├── utils/     kanshi
│   └── wm/        dispatcher, i3, niri, qtile, sway
├── gtk/           Colloid, Graphite, MacTahoe picker
├── qt/            qt5ct plus qt6ct plus Kvantum
├── noctalia-dell/ machine-specific Noctalia config (do not stow elsewhere)
├── noctalia-hp/   machine-specific Noctalia config (do not stow elsewhere)
├── .installer/    the dotfile manager (rich + questionary)
│   ├── manifests/ the only package names in the repo
│   └── hooks/     post-checkout, written by the hooks step
├── install.sh     entry point, bootstraps .venv then runs the menu
├── scripts/       theme skip-worktree helper
└── nix/           NixOS/Home Manager, see nix/paul-nix.md
```

Edits in the repo apply instantly once stowed, and `git diff` shows them.

## Conflicts

If a config exists in home and is not a link, the installer moves it aside
(`~/.config` becomes `~/.config.bak`), then stows. Nothing is deleted.

## GTK themes

Menu entry 5, or:

```sh
./install.sh themes
```

Picks Colloid, Graphite, MacTahoe, or all. Clones missing theme repos
(HTTPS fallback when SSH is absent), updates the rest, and runs each
theme's own installer. Files only. Your active theme stays put.

## Qt themes

Same entry as GTK. Installs `qt5ct`, `qt6ct`, `kvantum`, links the Kvantum
config here. Qt apps need `QT_QPA_PLATFORMTHEME=qt6ct` at WM startup. Sway
and qtile already set it.

## Noctalia (machine-specific, optional)

Dell and HP configs differ, both `.no-share`, so the installer skips them and
prints their warning. To apply one on purpose:

```sh
stow -d ~/dotfiles-pub -t ~ noctalia-dell   # or noctalia-hp
```

They hardcode `/home/paul` paths, so replace with `~` before copying
elsewhere.

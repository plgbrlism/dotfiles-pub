# Paul's dotfiles

Arch-first dotfiles, made for me, usable by others. Configs live here as
plain files. `stow` symlinks them into your home folder. If you dislike a
config, do not stow it.

## Prereqs

Arch with `pacman`, or NixOS with `nixos-rebuild`. Nix configs live in `nix/`.
You also need `git`, `stow`, `sudo`, and `fzf` (Arch only).

```sh
# Arch
sudo pacman -S --needed git stow fzf
```

`yay` is optional. The installer offers to fetch it when an AUR package
needs it.

## Install

```sh
git clone https://github.com/plgbrlism/dotfiles-pub ~/dotfiles-pub
cd ~/dotfiles-pub
./install.sh
```

`install.sh` starts a guided CLI built on `fzf`. One key model on every
screen: arrows move, typing filters, ENTER chooses, ESC or ctrl-c backs
out. There is no space key and no number keys. Multi-pick screens are
baskets: ENTER toggles a line, the Done line confirms. Nothing installs
until the review screen, where the cursor starts on Back, so ENTER never
installs blind.

## Arch menu

1. **Full install**: packages plus dotfiles plus hooks in one run. Choose
   apps and categories, review every package (descriptions included),
   unpick to remove, confirm.
2. **Install packages only**: `pacman`/`yay` for chosen apps and categories,
   same review screen. No stow.
3. **Apply dotfiles only**: symlink configs. Installs nothing.
4. **Switch branch**: `master` (stable calamus theme) or `dynamic` (live
   rizzoo theme variants).
5. **Update setup**: `git pull`, rewire hooks, redo recorded picks.
6. **Validate system**: PASS/WARNING/ERROR per check. Changes nothing.

Tick a whole category (for example `media`, `tools`, `browsers`) to pull
its packages. These install-only categories hold packages with no configs
to stow: `base`, `fonts`, `audio`, `browsers`, `media`, `desktop`, `tools`.
Picks are recorded, and Update reinstalls them. Kernel, boot, and drivers
(`linux`, `grub`, `xf86-video-*`) are install-time system layer, out of
scope here.

Apps present on your machine show `(installed)`. Entries flagged `.no-share`
are machine-specific and ask before stowing.

## NixOS menu

Packages and symlinks are declarative here, so the menu holds branch,
rebuild, update, and validate only. `nix/home/dotfiles.nix` symlinks the
same `~/.config` paths through home-manager. The CLI hides stow and package
entries so the two never fight over links.

## Branches

`master` pins the calamus colorscheme. `dynamic` tracks rizzoo-generated
`dynamic.*` baselines and re-marks them skip-worktree on checkout, so local
regenerations stay machine-specific and `git status` stays clean.

## Folders

```
dotfiles-pub/
├── apps/          one folder per app, each holding its real config
│   ├── cli/       btop, cava, fastfetch, glow, peaclock, rizzoo,
│   │              starship, yazi
│   ├── editor/    micro, nvim, zed
│   ├── service/   xdg-desktop-portal
│   ├── terminal/  foot, kitty
│   ├── tty/       xresources
│   ├── utils/     kanshi
│   └── wm/        dispatcher, niri, sway
├── gtk/           MacTahoe
├── qt/            qt5ct plus qt6ct plus Kvantum
├── noctalia-dell/ machine-specific Noctalia config (do not stow elsewhere)
├── noctalia-hp/   machine-specific Noctalia config (do not stow elsewhere)
├── installer/     the Python/fzf installer package
├── install.sh     entry point, launches installer/
├── scripts/       git hooks plus theme helpers
└── nix/           NixOS/Home Manager, see nix/paul-nix.md
```

Edits in the repo apply instantly once stowed, and `git diff` shows them.

## Conflicts

If a config exists in home and is not a link, the installer moves it aside
(`~/.config` becomes `~/.config.bak`), then stows. Nothing is deleted.

## GTK themes

```sh
cd ~/dotfiles-pub/gtk/mac-tahoe
./reload.sh
```

Picks MacTahoe. Clones the missing theme repo
(HTTPS fallback when SSH is absent), updates the rest, and runs the
theme's own installer. Files only. Your active theme stays put.

## Qt themes

```sh
stow -d ~/dotfiles-pub -t ~ qt
```

Installs `qt5ct`, `qt6ct`, `kvantum`, links the Kvantum config here.
Qt apps need `QT_QPA_PLATFORMTHEME=qt6ct` at WM startup. Sway
already sets it.

## Noctalia (machine-specific, optional)

Dell and HP configs differ. Offered in `./install.sh` under `noctalia`, or:

```sh
stow -d ~/dotfiles-pub -t ~ noctalia-dell   # or noctalia-hp
```

Both are `.no-share`. They hardcode `/home/paul` paths, so replace with
`~` before copying elsewhere.

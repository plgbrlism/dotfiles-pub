# my messy asf dotfile repository :>

Arch-first dotfiles. Configs live here as plain files, and `stow` symlinks them
into your home folder when you want them. Nothing is hidden in scripts — if you
don't like a config, don't stow it.

## What you need first

- **Linux**: Arch (the installers below assume `pacman`). Nix configs live in
  `nix/` and are separate.
- **Tools**: `git`, `gum` (menus), `stow` (the symlinker), `sudo`.

```sh
sudo pacman -S --needed git gum stow
```

`yay` is optional. It's only needed for AUR packages, and the installer offers to
fetch it for you if it's missing.

## The one command

```sh
git clone https://github.com/plgbrlism/dotfiles-pub ~/dotfiles-pub   # or git@github.com:plgbrlism/dotfiles-pub.git
cd ~/dotfiles-pub
./install.sh
```

`install.sh` is a set of `gum` menus — nothing installs until you pick it:

1. **Mode** — `Install + stow` (install packages, then link configs) or
   `Stow only` (configs already installed, just link them).
2. **Categories** — pick any of `bar`, `cli`, `compositor`, `editor`, `launcher`,
   `locker`, `notifier`, `terminal`, `utils`, `wm`, plus `gtk` and `qt`.
3. **Apps** — per category, pick what you want. Apps already on your machine show
   up tagged `[installed]`.
4. **Confirmation** — if some picks are already installed, it asks whether to
   skip reinstalling them and only link their configs.
5. **Install** — one `pacman` run, one `yay` run. Not one command per app.

Then it links your configs with `stow`.

## How the folders work

```
dotfiles-pub/
├── apps/          ← one folder per app, each holding its real config
│   ├── bar/       ← polybar, waybar
│   ├── cli/       ← btop, cava, starship, ...
│   ├── compositor/← picom
│   ├── editor/    ← micro, nvim, zed
│   ├── launcher/  ← rofi
│   ├── locker/    ← hyprlock
│   ├── notifier/  ← dunst
│   ├── terminal/  ← alacritty, foot, ghostty, kitty
│   ├── utils/     ← kanshi
│   └── wm/        ← sway, niri, qtile, i3
├── gtk/           ← GTK theme picker (Colloid, Graphite, MacTahoe)
├── qt/            ← qt5ct + qt6ct + Kvantum
├── install.sh     ← the installer
└── nix/           ← NixOS/Home Manager, see nix/paul-nix.md
```

Each app folder holds that app's real config under a dotfile path. Stowing an
app links those files into your home folder, so edits in the repo apply
instantly and `git diff` shows what you changed.

## Conflicts

If a config already exists in your home folder and isn't a link, the installer
moves it aside first (e.g. `~/.config` → `~/.config.bak`) then stows. Nothing is
deleted. Merge anything you want back.

## GTK themes

```sh
cd ~/dotfiles-pub/gtk
./setup-gtk.sh
```

Menu of Colloid, Graphite, MacTahoe, or all at once. Clones any theme repo
you're missing (HTTPS if SSH isn't set up), keeps the rest up to date, clears out
the other theme variants, and runs the theme's own installer. It installs files
only — it won't change your current theme.

## Qt themes

```sh
cd ~/dotfiles-pub/qt
./setup-qt.sh
```

Installs `qt5ct`, `qt6ct`, and `kvantum`, then links the Kvantum config here.
Qt apps need `QT_QPA_PLATFORMTHEME=qt6ct` in your window manager's startup —
sway and qtile already have it.

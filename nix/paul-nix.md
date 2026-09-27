# My Nix Setup

everything lives in one folder, each file does one job, and one command rebuilds the whole thing.

```
nix/
├── flake.nix     ← starts everything
├── home/         ← my stuff (dotfiles, shell, git)
├── hosts/        ← my machines
└── modules/      ← one file per topic
```

| Folder | What it answers |
|---|---|
| `flake.nix` | What's installed and from where? |
| `home/` | How do I like my computer set up? |
| `hosts/` | Which machine is this for? |
| `modules/` | What does the machine do? |

## `flake.nix`

| Does | Means |
|---|---|
| One starting point | `nixos-rebuild` picks it up, everything follows |
| Locks the packages | Same setup every time, nothing randomly breaks |
| Names my laptop `hp` | So I can tell Nix which machine to build |
| Hooks up `home/` | My personal settings get applied too |

## `home/`

| File | What's in it |
|---|---|
| `default.nix` | My username, my editor, brings in the rest |
| `shell.nix` | Zsh, prompt, my shortcuts |
| `git.nix` | Git setup, kept in one place |
| `dotfiles.nix` | Points Nix at my dotfile folders |

**The dotfiles trick:** app configs (terminal, editor, etc.) live in their own repos, not here. Nix just links them into place. Keeps this repo clean and secrets out of the public one.

## `hosts/`

| File | What's in it |
|---|---|
| `configuration.nix` | The machine's list of settings |
| `hardware-configuration.nix` | Auto-generated. Don't touch it |

Just `hp/` (my laptop) today. New machine = new folder here.

## `modules/`

One topic per file. Nothing in here imports anything else, so each file is easy to read on its own.

| Module | About |
|---|---|
| `boot.nix` | How the machine starts up |
| `hardware.nix` | Chips, graphics, drivers |
| `networking.nix` | Wi-Fi, firewall, sharing |
| `audio.nix` | Sound |
| `desktop.nix` | Login screen and desktop basics |
| `window-managers.nix` | My tiling window setups (i3, Sway, Niri) |
| `fonts.nix` | Fonts |
| `virtualisation.nix` | Docker |
| `power.nix` | Battery life, extra memory |
| `services.nix` | Bluetooth, file mounts, permissions |
| `ssh.nix` | Remote login |
| `build.nix` | Build tools and compilers |
| `programmes.nix` | Everyday CLI programs |
| `packages.nix` | Bigger apps: browsers, media, office |

## Why it's split up

| Want to… | Do this |
|---|---|
| Turn something off | Remove one file from the list |
| Change startup settings | Edit `boot.nix` only |
| Add a machine | Copy a folder in `hosts/` |
| Try something risky | Put it in its own file first |

## Context

This runs on a low-power laptop with 4GB RAM, so the settings lean small: no fancy effects, Bluetooth off at boot, extra memory instead of a big disk swap, battery tools switched on. I also have two desktop styles to pick from — the lighter X11 one and the Wayland ones.

## Rebuilding

```bash
sudo nixos-rebuild switch --flake .#hp
```

That's it. Everything gets applied.

---

*Last updated: September 2026*

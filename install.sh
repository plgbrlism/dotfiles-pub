#!/usr/bin/env bash
set -euo pipefail

# categorized installer + stower for apps/* 
# usage: ./install.sh (interactive, gum)
ROOT="$HOME/dotfiles-pub"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Error: '$1' not found. Install it first." >&2; exit 1; }
}
need gum
need stow
need pacman
command -v sudo >/dev/null 2>&1 || { echo "Error: sudo not found." >&2; exit 1; }

# cat|dir|pacman pkgs|aur pkgs|bin|stow-ignore
APPS="bar|polybar|polybar||polybar|
bar|waybar|waybar||waybar|
capture|flameshot|flameshot||flameshot|
cli|btop|btop||btop|
cli|cava|cava||cava|
cli|fastfetch|fastfetch||fastfetch|
cli|glow|glow||glow|
cli|lavat||lavat-git|lavat|
cli|peaclock||peaclock|peaclock|history
cli|starship|starship||starship|
cli|yazi|yazi||yazi|
compositor|picom|picom||picom|
editor|micro|micro||micro|
editor|nvim|neovim||nvim|
editor|zed|zed||zed|
file|xarchiver|xarchiver||xarchiver|
launcher|rofi|rofi||rofi|
locker|hyprlock|hyprlock||hyprlock|
note|obsidian|obsidian||obsidian|
notifier|dunst|dunst||dunst|
service|xdg-desktop-portal|xdg-desktop-portal-wlr xdg-desktop-portal-gtk|||
shell|zsh|zsh||zsh|
terminal|alacritty|alacritty||alacritty|
terminal|foot|foot||foot|
terminal|ghostty|ghostty||ghostty|
terminal|kitty|kitty||kitty|
utils|kanshi|kanshi||kanshi|
wm|helper||||
wm|dispatcher||||dispatch|
wm|i3|i3-wm||i3|
wm|niri||niri-git|niri|
wm|qtile|qtile|qtile-extras-git|qtile|__pycache__
wm|sway|swaybg swaylock|swayfx|sway|"

field() { echo "$1" | cut -d'|' -f"$2"; }

installed_bin() { [ -n "$1" ] && command -v "$1" >/dev/null 2>&1; }
pkg_done() { pacman -Q "$1" >/dev/null 2>&1; }

ensure_yay() {
  command -v yay >/dev/null 2>&1 && return 0
  echo "yay missing, bootstrapping yay-bin..."
  sudo pacman -S --needed --noconfirm base-devel git
  rm -rf /tmp/yay-bin
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
  (cd /tmp/yay-bin && makepkg -si --noconfirm)
}

# move clashing top-level entries aside, then stow.
# skips .no-share / .do-not-stow.md themselves so they never land in $HOME.
stow_app() {
  local cat="$1" dir="$2" ignore="$3" pkg top target scope warn eff_ignore
  pkg="$ROOT/apps/$cat/$dir"
  for scope in "$ROOT/apps/$cat" "$pkg"; do
    if [ -f "$scope/.no-share" ]; then
      warn="$scope/.do-not-stow.md"
      [ -f "$warn" ] && cat "$warn"
      gum confirm "Stow $dir anyway (not recommended - configure on own)?" \
        || { echo "$dir: skipped (.no-share - configure on own)."; return 0; }
      break
    fi
  done
  for top_path in "$pkg"/.[!.]* "$pkg"/*; do
    [ -e "$top_path" ] || continue
    top=$(basename "$top_path")
    case "$top" in .no-share|.do-not-stow.md) continue;; esac
    target="$HOME/$top"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      mv "$target" "$target.bak" && echo "Backed up $target to $target.bak."
    fi
  done
  eff_ignore="\\.do-not-stow\\.md"
  [ -n "$ignore" ] && eff_ignore="($ignore|$eff_ignore)"
  stow -d "$ROOT/apps/$cat" -t "$HOME" --ignore="$eff_ignore" "$dir"
}

# stow a top-level package (noctalia-dell) straight from ROOT.
stow_top() {
  local pkg="$1" label="$2" src top target warn
  src="$ROOT/$pkg"
  if [ -f "$src/.no-share" ]; then
    warn="$src/.do-not-stow.md"
    [ -f "$warn" ] && cat "$warn"
    gum confirm "Stow $label anyway (not recommended - configure on own)?" \
      || { echo "$label: skipped (.no-share - configure on own)."; return 0; }
  fi
  for top_path in "$src"/.[!.]* "$src"/*; do
    [ -e "$top_path" ] || continue
    top=$(basename "$top_path")
    case "$top" in .no-share|.do-not-stow.md|.git*) continue;; esac
    target="$HOME/$top"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      mv "$target" "$target.bak" && echo "Backed up $target to $target.bak."
    fi
  done
  stow -d "$ROOT" -t "$HOME" --ignore="\\.do-not-stow\\.md" "$pkg" && echo "$label: stowed."
}

link_helper() {
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$ROOT/apps/wm/helper/generic-launcher" "$HOME/.local/bin/generic-launcher"
  echo "Linked generic-launcher to ~/.local/bin."
}

MODE=$(gum choose --header "Mode?" "Install + stow" "Stow only") || exit 1

CATS=$(printf 'bar\ncapture\ncli\ncompositor\neditor\nenv\nfile\nlauncher\nlocker\nnote\nnotifier\nservice\nshell\nterminal\ntty\nutils\nwm\nnoctalia\ngtk\nqt' \
  | gum choose --no-limit --header "Categories? ('x' to pick/toggle)") || exit 1
[ -n "$CATS" ] || { echo "Nothing selected."; exit 0; }

SELECTED=""
for cat in $CATS; do
  case "$cat" in
    gtk|qt|env|tty|noctalia) SELECTED="$SELECTED
$cat|.|.|.|.|" ;;
    *)
      opts=""
      while IFS= read -r e; do
        d=$(field "$e" 2); b=$(field "$e" 5)
        if installed_bin "$b"; then tag=" [installed]"; else tag=""; fi
        opts="$opts$d$tag
"
      done <<< "$(echo "$APPS" | grep "^$cat|")"
      picked=$(printf '%s' "$opts" | grep . | gum choose --no-limit --header "$cat apps? ('x' to pick/toggle)") || true
      while IFS= read -r p; do
        [ -n "$p" ] || continue
        d=${p% *}
        SELECTED="$SELECTED
$(echo "$APPS" | grep "^$cat|$d|")"
      done <<< "$picked"
      ;;
  esac
done

if [ "$MODE" = "Install + stow" ]; then
  # offer stow-only for already installed apps.
  present=""
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    b=$(field "$e" 5)
    installed_bin "$b" && present="$present$(field "$e" 2) "
  done <<< "$SELECTED"
  if [ -n "$present" ]; then
    gum confirm "Already installed ($present)- stow configs only for these?" \
      && STOW_ONLY="$present" || STOW_ONLY=""
  else
    STOW_ONLY=""
  fi

  PAC_MISSING=""; AUR_MISSING=""
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    case "$e" in gtk\||qt\||noctalia\|) continue;; esac
    d=$(field "$e" 2)
    case " $STOW_ONLY " in *" $d "*) continue;; esac
    for p in $(field "$e" 3); do pkg_done "$p" || PAC_MISSING="$PAC_MISSING$p "; done
    for p in $(field "$e" 4); do pkg_done "$p" || AUR_MISSING="$AUR_MISSING$p "; done
  done <<< "$SELECTED"
  # shellcheck disable=SC2086
  [ -z "$PAC_MISSING" ] || sudo pacman -S --needed --noconfirm $PAC_MISSING
  if [ -n "$AUR_MISSING" ]; then
    ensure_yay
    # shellcheck disable=SC2086
    yay -S --needed --noconfirm $AUR_MISSING
  fi
fi

sudo -v # keep alive for chained scripts that may sudo
while IFS= read -r e; do
  [ -n "$e" ] || continue
  cat=$(field "$e" 1); d=$(field "$e" 2)
  case "$cat" in
    gtk) echo "NOTE: gtk marked .no-share - see gtk/.do-not-stow.md (vendored themes)."; bash "$ROOT/gtk/setup-gtk.sh"; echo "gtk: done."; continue;;
    qt) echo "NOTE: qt marked .no-share - see qt/.do-not-stow.md (Arch-only)."; bash "$ROOT/qt/setup-qt.sh"; echo "qt: done."; continue;;
    env) stow -d "$ROOT/apps" -t "$HOME" env && echo "env: stowed (.xinitrc/.xprofile/.zprofile)."; continue;;
    tty) stow -d "$ROOT/apps" -t "$HOME" tty && echo "tty: stowed (.Xresources)."; continue;;
    noctalia)
      pick=$(gum choose --header "Machine? (dell/hp configs differ - pick yours)" "dell" "hp") || continue
      stow_top "noctalia-$pick" "noctalia-$pick" && echo "noctalia-$pick: done."
      continue;;
  esac
  if [ "$cat" = "shell" ] && [ "$d" = "zsh" ]; then
    echo "NOTE: zsh config needs oh-my-zsh for full setup (see https://oh-my-zsh.sh)."
  fi
  if [ "$cat" = "wm" ] && [ "$d" = "helper" ]; then
    link_helper; continue
  fi
  if [ "$MODE" = "Install + stow" ] && [ -z "$(field "$e" 3)$(field "$e" 4)" ]; then
    installed_bin "$(field "$e" 5)" \
      && echo "$d: no repo package (cargo/manual install), binary present." \
      || echo "$d: no repo package (cargo/manual install), binary MISSING - stowing anyway."
  fi
  stow_app "$cat" "$d" "$(field "$e" 6)" && echo "$d: stowed."
done <<< "$SELECTED"

gum style --foreground 212 "Done."

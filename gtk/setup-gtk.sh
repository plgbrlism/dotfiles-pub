#!/usr/bin/env bash
set -euo pipefail

GTK_ROOT="$HOME/dotfiles-pub/gtk"
THEMES_DIR="$HOME/.themes"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Error: '$1' not found. Install it first." >&2; exit 1; }
}

need git
need gum

# name|subdir|repo-path|reload-script|flatpak-prefix
THEMES="colloid|colloid/Colloid-gtk-theme|vinceliuice/Colloid-gtk-theme.git|colloid/reload.sh|Colloid
graphite|graphite/Graphite-gtk-theme|vinceliuice/Graphite-gtk-theme.git|graphite/reload.sh|Graphite
mac-tahoe|mac-tahoe/MacTahoe-gtk-theme|vinceliuice/MacTahoe-gtk-theme.git|mac-tahoe/reload.sh|Mac"

ensure_clone() {
  local dir="$1" repo="$2"
  if [ -x "$dir/install.sh" ]; then
    git -C "$dir" pull --ff-only 2>/dev/null || echo "Note: could not update $(basename "$dir"), using local copy."
    return 0
  fi
  mkdir -p "$(dirname "$dir")"
  git clone "git@github.com:$repo" "$dir" 2>/dev/null \
    || git clone "https://github.com/${repo%.git}" "$dir"
}

install_core() {
  local entry="$1" dir repo reload
  dir="$GTK_ROOT/$(echo "$entry" | cut -d'|' -f2)"
  repo=$(echo "$entry" | cut -d'|' -f3)
  reload="$GTK_ROOT/$(echo "$entry" | cut -d'|' -f4)"

  ensure_clone "$dir" "$repo"
  bash "$reload"
}

flatpak_setup() {
  local prefix="${1:-}" installed
  command -v flatpak >/dev/null 2>&1 || return 0
  if [ -n "$prefix" ]; then
    installed=$(ls -d "$THEMES_DIR"/"$prefix"* 2>/dev/null | head -n 1 | xargs basename 2>/dev/null || true)
  fi
  flatpak override --user \
    --filesystem="$HOME/.themes" \
    --filesystem="$HOME/.config/gtk-4.0" \
    ${installed:+--env=GTK_THEME=$installed} || echo "Note: flatpak override failed, continuing."
}

install_one() {
  local entry="$1"
  install_core "$entry"
  flatpak_setup "$(echo "$entry" | cut -d'|' -f5)"
}

CHOICE=$(printf '%s\nall' "$(echo "$THEMES" | cut -d'|' -f1)" | gum choose --header "GTK theme?") || exit 1

# remove only the three gtk variants, not the whole ~/.themes.
rm -rf "$THEMES_DIR"/Colloid* "$THEMES_DIR"/Graphite* "$THEMES_DIR"/Mac*

if [ "$CHOICE" = "all" ]; then
  fails=0
  while IFS= read -r entry; do install_core "$entry" & done <<< "$THEMES"
  for job in $(jobs -p); do wait "$job" || fails=$((fails + 1)); done
  [ "$fails" -eq 0 ] || { echo "Error: $fails theme(s) failed." >&2; exit 1; }
  flatpak_setup
else
  install_one "$(echo "$THEMES" | grep "^$CHOICE|")"
fi

gum style --foreground 212 "Done: $CHOICE installed."

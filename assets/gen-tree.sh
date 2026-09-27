#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/dotfiles-pub}"
SECTION="${2:-all}"

META=$(cat <<'EOF'
apps/wm/i3|X11|
apps/wm/sway|WL|
apps/wm/niri|WL|
apps/wm/qtile|BOTH|
apps/wm/helper|SHELL|symlinked to ~/.local/bin, not stowed
apps/bar/polybar|X11|
apps/bar/waybar|WL|
apps/terminal/alacritty|BOTH|
apps/terminal/foot|BOTH|
apps/terminal/ghostty|BOTH|
apps/terminal/kitty|BOTH|
apps/cli/btop|SHELL|
apps/cli/cava|SHELL|
apps/cli/fastfetch|SHELL|
apps/cli/lavat|SHELL|
apps/cli/peaclock|SHELL|history ignored on stow
apps/cli/rizzoo|SHELL|
apps/cli/starship|SHELL|
apps/compositor/picom|X11|
apps/editor/micro|BOTH|
apps/editor/nvim|BOTH|
apps/editor/zed|BOTH|
apps/launcher/rofi|BOTH|
apps/locker/hyprlock|WL|
apps/notifier/dunst|X11|
apps/utils/kanshi|BOTH|
gtk/colloid|BOTH|cloned on demand, SSH→HTTPS fallback
gtk/graphite|BOTH|cloned on demand, SSH→HTTPS fallback
gtk/mac-tahoe|BOTH|cloned on demand, SSH→HTTPS fallback
qt/kvantum|BOTH|KvMaterial theme linked
noctalia-dell|BOTH|dell laptop overlay
noctalia-hp|BOTH|hp laptop overlay
EOF
)

esc() { sed 's/&/\&/g;s/</\</g;s/>/\>/g'; }

badge_class() {
  case "$1" in
    X11) echo "x11" ;;
    WL) echo "wl" ;;
    BOTH) echo "both" ;;
    SHELL) echo "shell" ;;
    *) echo "both" ;;
  esac
}

is_excluded() {
  case "$1" in
    *__pycache__*|*/.venv*|*/.ruff_cache*|*/.git*|*/Colloid-gtk-theme*|*/Graphite-gtk-theme*|*/MacTahoe-gtk-theme*|*/lazy-lock.json|*/lazyvim.json|*/colors/__pycache__*)
      return 0 ;;
  esac
  return 1
}

should_include() {
  local prefix="$1"
  case "$SECTION" in
    wm)     [[ "$prefix" == apps/wm/* ]] ;;
    bar)    [[ "$prefix" == apps/bar/* ]] ;;
    term)   [[ "$prefix" == apps/terminal/* ]] ;;
    cli)    [[ "$prefix" == apps/cli/* ]] ;;
    editor) [[ "$prefix" == apps/editor/* ]] ;;
    misc)   [[ "$prefix" == apps/launcher/* || "$prefix" == apps/locker/* || "$prefix" == apps/notifier/* || "$prefix" == apps/compositor/* || "$prefix" == apps/utils/* ]] ;;
    theme)  [[ "$prefix" == gtk/* || "$prefix" == qt/* ]] ;;
    overlay)[[ "$prefix" == noctalia-* ]] ;;
    nix)    [[ "$prefix" == nix/* ]] ;;
    root)   [[ "$prefix" != apps/* && "$prefix" != gtk/* && "$prefix" != qt/* && "$prefix" != noctalia-* && "$prefix" != nix/* ]] ;;
    *) return 0 ;;
  esac
}

walk() {
  local dir="$1" prefix="$2" depth="$3"
  local entries=() name rel_path is_dir badge comment line
  while IFS= read -r -d '' entry; do
    entries+=("$entry")
  done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null | sort -z)

  local count=${#entries[@]}
  local i=0
  for entry in "${entries[@]}"; do
    i=$((i+1))
    name=$(basename "$entry")
    rel_path="${prefix}${name}"
    is_dir=0
    [ -d "$entry" ] && is_dir=1

    if is_excluded "$entry"; then
      continue
    fi
    if ! should_include "$prefix${name}"; then
      continue
    fi

    badge="BOTH"
    comment=""
    if [ -n "$META" ]; then
      while IFS='|' read -r m_path m_badge m_comment; do
        if [ "$rel_path" = "$m_path" ]; then
          badge="$m_badge"
          comment="$m_comment"
          break
        fi
      done <<< "$META"
    fi

    if [ $is_dir -eq 1 ]; then
      line="<details><summary><div class=\"row\"><span class=\"icon\">&#x1f4c2;</span><span class=\"label dir\">${name}/</span>"
      [ -n "$badge" ] && line+="<span class=\"badge $(badge_class "$badge")\">$badge</span>"
      [ -n "$comment" ] && line+="<span class=\"label comment\">$comment</span>"
      line+="</div></summary>"
      echo "$line"
      echo "<ul>"
      walk "$entry" "${prefix}${name}/" $((depth+1))
      echo "</ul>"
      echo "</details>"
    else
      if [ $i -eq $count ]; then
        icon="└"
      else
        icon="├"
      fi
      line="<div class=\"row\"><span class=\"icon\">${icon}</span><span class=\"label file\">${name}</span>"
      [ -n "$comment" ] && line+="<span class=\"label comment\">$comment</span>"
      line+="</div>"
      echo "$line"
    fi
  done
}

case "$SECTION" in
  wm) walk "$ROOT/apps/wm" "apps/wm/" 0 ;;
  bar) walk "$ROOT/apps/bar" "apps/bar/" 0 ;;
  term) walk "$ROOT/apps/terminal" "apps/terminal/" 0 ;;
  cli) walk "$ROOT/apps/cli" "apps/cli/" 0 ;;
  editor) walk "$ROOT/apps/editor" "apps/editor/" 0 ;;
  misc) walk "$ROOT/apps/launcher" "apps/launcher/" 0; walk "$ROOT/apps/locker" "apps/locker/" 0; walk "$ROOT/apps/notifier" "apps/notifier/" 0; walk "$ROOT/apps/compositor" "apps/compositor/" 0; walk "$ROOT/apps/utils" "apps/utils/" 0 ;;
  theme) walk "$ROOT/gtk" "gtk/" 0; walk "$ROOT/qt/kvantum" "qt/kvantum/" 0 ;;
  overlay) walk "$ROOT/noctalia-dell" "noctalia-dell/" 0; walk "$ROOT/noctalia-hp" "noctalia-hp/" 0 ;;
  nix) walk "$ROOT/nix" "nix/" 0 ;;
  root)
    for f in "$ROOT"/install.sh "$ROOT"/README.md "$ROOT"/assets/*.sh "$ROOT"/dotfiles_tree_structure.html; do
      [ -e "$f" ] && echo "<div class=\"row\"><span class=\"icon\">└</span><span class=\"label file\">$(basename "$f")</span></div>"
    done
    ;;
  *) walk "$ROOT/apps" "apps/" 0; walk "$ROOT/gtk" "gtk/" 0; walk "$ROOT/qt/kvantum" "qt/kvantum/" 0; walk "$ROOT/noctalia-dell" "noctalia-dell/" 0; walk "$ROOT/noctalia-hp" "noctalia-hp/" 0; walk "$ROOT/nix" "nix/" 0 ;;
esac
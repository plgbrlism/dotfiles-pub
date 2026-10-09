#!/usr/bin/env bash
# Paul dotfiles installer — bash + gum, Arch only.
# Menu-driven: pick apps/categories, review packages, stow dotfiles.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
STATE_DIR="$HOME/.local/state/paul-dotfiles-installer"
STATE_FILE="$STATE_DIR/installed.txt"
LOGFILE=""

# --- logging -------------------------------------------------------------
logfile() {
  mkdir -p "$STATE_DIR"
  LOGFILE="$STATE_DIR/$(date +%Y%m%d-%H%M%S).log"
}
say() { echo "$*"; [ -n "$LOGFILE" ] && echo "$*" >>"$LOGFILE"; }
run() {
  say "\$ $*"
  "$@" 2>&1 | while IFS= read -r line; do say "$line"; done
  return "${PIPESTATUS[0]}"
}

# --- deps ----------------------------------------------------------------
if ! command -v gum >/dev/null 2>&1; then
  echo "bootstrap: installing gum..."
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm gum
  else
    echo "error: Arch/pacman required." >&2
    exit 1
  fi
fi
for dep in git stow pacman; do
  command -v "$dep" >/dev/null 2>&1 || { echo "error: $dep missing." >&2; exit 1; }
done

# --- package table -------------------------------------------------------
# cat|dir|pacman pkgs (space-sep)|aur pkgs (space-sep)|bin|stow-ignore
APPS=$(
  cat <<'EOF'
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
EOF
)

CATEGORIES="cli editor service terminal tty utils wm noctalia gtk qt base fonts audio browsers media desktop tools"
SPECIAL_CATS="noctalia gtk qt tty"
INSTALL_CATS="base fonts audio browsers media desktop tools"

# install-only category package groups: name -> "pacman:... ; aur:..."
cat_pkgs() {
  case "$1" in
  base) echo "pacman:git stow base-devel fzf fd bat tldr zoxide tmux zsh-autosuggestions zsh-syntax-highlighting;aur:yay-bin" ;;
  fonts) echo "pacman:noto-fonts noto-fonts-emoji ttf-firacode-nerd ttf-jetbrains-mono-nerd ttf-liberation ttf-dejavu;aur:otf-departure-mono-nerd ttf-ms-fonts ttf-unifont siji-ttf" ;;
  audio) echo "pacman:pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber pavucontrol;aur:" ;;
  browsers) echo "pacman:firefox;aur:brave-origin-bin google-chrome zen-browser-bin" ;;
  media) echo "pacman:mpv vlc imv feh inkscape krita obs-studio peek gpu-screen-recorder grim wl-clipboard gst-plugin-pipewire ffmpegthumbnailer poppler tumbler xwallpaper imagemagick;aur:gpu-screen-recorder-gtk" ;;
  desktop) echo "pacman:bitwarden anki nautilus lxappearance nwg-look xss-lock;aur:vesktop-bin onlyoffice-bin unityhub cursor-appimage megacmd clyp-bin universal-android-debloater-bin aura-git veila-git wbg i3lock-color i3lock-fancy-rapid-git" ;;
  tools) echo "pacman:lazygit atuin just jq tree rsync wget dust pastel xclip autorandr brightnessctl bluetui bluez bluez-utils tlp powertop fwupd pacman-contrib systemctl-tui smartmontools lsof vhs awww cowsay figlet cmatrix 7zip unzip;aur:" ;;
  *) echo "pacman:;aur:" ;;
  esac
}

# --- package queries -----------------------------------------------------
pkg_installed() { pacman -Q "$1" >/dev/null 2>&1; }
app_installed() { # cat|name row fields via globals: $pac $aur $bin
  if [ -n "$bin" ] && command -v "$bin" >/dev/null 2>&1; then return 0; fi
  for p in $pac $aur; do pkg_installed "$p" || return 1; done
  [ -n "$pac$aur" ]
}
missing_of() { # space-sep pkgs -> missing subset
  local out=""
  for p in $1; do pkg_installed "$p" || out="$out $p"; done
  echo "$out"
}
pkg_desc() { pacman -Si "$1" 2>/dev/null | awk -F': ' '/^Description/ {print $2; exit}'; }

ensure_yay() {
  command -v yay >/dev/null 2>&1 && return 0
  say "yay missing, bootstrapping yay-bin..."
  run sudo pacman -S --needed --noconfirm base-devel git || return 1
  rm -rf /tmp/yay-bin
  run git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin || return 1
  (cd /tmp/yay-bin && run makepkg -si --noconfirm)
}

install_explicit() { # $1=pac list $2=aur list
  if [ -n "$1$2" ]; then
    say "sudo: caching credentials (a password prompt may appear)."
    run sudo -v || return 1
  fi
  [ -z "$1" ] || run sudo pacman -S --needed --noconfirm $1 || return 1
  if [ -n "$2" ]; then
    ensure_yay || return 1
    run yay -S --needed --noconfirm $2 || return 1
  fi
  [ -n "$1$2" ] || say "Nothing to install."
}

# --- stow ----------------------------------------------------------------
no_share_file() { # $1=cat $2=name -> marker path or empty
  for scope in "$ROOT/apps/$1" "$ROOT/apps/$1/$2"; do
    [ -e "$scope/.no-share" ] && { echo "$scope/.no-share"; return 0; }
  done
  return 1
}
backup_conflicts() { # $1=pkg dir
  for child in "$1"/*; do
    [ -e "$child" ] || continue
    base=$(basename "$child")
    case "$base" in .no-share | .do-not-stow.md | .git*) continue ;; esac
    if [ -e "$HOME/$base" ] && [ ! -L "$HOME/$base" ]; then
      say "Backed up $HOME/$base to $HOME/$base.bak"
      mv "$HOME/$base" "$HOME/$base.bak"
    fi
  done
}
stow_app() { # $1=cat $2=name $3=ignore
  local pkg="$ROOT/apps/$1/$2"
  [ -d "$pkg" ] || { say "$2: $pkg not found, skipped."; return 1; }
  local marker
  if marker=$(no_share_file "$1" "$2") && [ "$FORCE" != "1" ]; then
    [ -f "$(dirname "$marker")/.do-not-stow.md" ] && cat "$(dirname "$marker")/.do-not-stow.md"
    say "$2: marked .no-share at $(basename "$(dirname "$marker")")/ - skipped."
    return 0
  fi
  backup_conflicts "$pkg"
  local eff="\\.do-not-stow\\.md"
  [ -n "$3" ] && eff="($3|$eff)"
  say "stow $2"
  run stow -d "$ROOT/apps/$1" -t "$HOME" "--ignore=$eff" "$2"
}
stow_top() { # $1=top-level pkg dir
  local src="$ROOT/$1"
  if [ -e "$src/.no-share" ] && [ "$FORCE" != "1" ]; then
    [ -f "$src/.do-not-stow.md" ] && cat "$src/.do-not-stow.md"
    say "$1: marked .no-share - skipped (confirm to override)."
    return 0
  fi
  backup_conflicts "$src"
  say "stow $1"
  run stow -d "$ROOT" -t "$HOME" "--ignore=\\.do-not-stow\\.md" "$1"
}
apply_cat() { # $1=cat $2=noctalia-machine
  case "$1" in
  base | fonts | audio | browsers | media | desktop | tools)
    say "$1: packages only, handled in package step."
    ;;
  tty) say "stow $1"; run stow -d "$ROOT/apps" -t "$HOME" "$1" ;;
  gtk)
    say "NOTE: gtk is .no-share; running mac-tahoe reload.sh"
    run bash "$ROOT/gtk/mac-tahoe/reload.sh"
    ;;
  qt) stow_top "qt" ;;
  noctalia)
    if [ -n "$2" ]; then
      stow_top "noctalia-$2"
    else
      say "noctalia: no machine given, skipped. stow -d ~/dotfiles-pub -t ~ noctalia-dell (or -hp) manually."
    fi
    ;;
  esac
}

# --- state ---------------------------------------------------------------
is_install_cat() { case " $INSTALL_CATS " in *" $1 "*) return 0 ;; esac; return 1; }
record_installed() { # stdin lines appended, sorted unique
  mkdir -p "$STATE_DIR"
  { [ -f "$STATE_FILE" ] && cat "$STATE_FILE"; cat; } | sort -u | grep -v '^$' >"$STATE_FILE.tmp" || true
  mv "$STATE_FILE.tmp" "$STATE_FILE"
}
recorded_apps() { grep '|' "$STATE_FILE" 2>/dev/null || true; }
recorded_cats() { grep '^@' "$STATE_FILE" 2>/dev/null | grep -v '^@rebuild:' | sed 's/^@//' || true; }

# --- git -----------------------------------------------------------------
current_branch() { git branch --show-current 2>/dev/null; }
wire_hooks() {
  git config core.hooksPath scripts/git-hooks
  say "git: core.hooksPath -> scripts/git-hooks"
}
mark_theme_local() { [ -x scripts/mark-theme-local.sh ] && run bash scripts/mark-theme-local.sh || true; }

# --- ui: pick ------------------------------------------------------------
pick_entries() { # stdout: display lines; values before "  (installed)"
  local cat name pac aur bin ignore
  for cat in $CATEGORIES; do
    case " $SPECIAL_CATS " in *" $cat "*) echo "$cat/  (whole category)" && continue ;; esac
    case " $INSTALL_CATS " in *" $cat "*) echo "$cat/  (whole category, packages only)" && continue ;; esac
    while IFS='|' read -r c name pac aur bin ignore; do
      [ "$c" = "$cat" ] || continue
      if app_installed; then echo "$cat/$name  (installed)"; else echo "$cat/$name"; fi
    done <<<"$APPS"
  done
}
strip_label() { sed -e 's|/  (whole category.*||' -e 's|  (installed)$||' -e 's|/$||'; } # value: cat/name or cat

run_pick() { # $1=mode: install+stow | packages | stow
  local mode="$1" has_pkgs=0 last="2"
  case "$mode" in install+stow | packages) has_pkgs=1; last="3" ;; esac
  while true; do
    mapfile -t picked < <(pick_entries | gum choose --no-limit --header "Step 1 of $last: choose apps/categories (space toggles)" || true)
    [ "${#picked[@]}" -gt 0 ] || return 0
    local values=() cats=() apps=()
    for p in "${picked[@]}"; do values+=("$(echo "$p" | strip_label)"); done
    for v in "${values[@]}"; do
      case "$v" in */*) apps+=("$v") ;; *) cats+=("$v") ;; esac
    done

    local noctalia=""
    if [[ " ${cats[*]} " == *" noctalia "* ]]; then
      noctalia=$(gum choose --header "Which machine for noctalia?" dell hp) || continue
    fi

    # missing-only package plan
    local pac="" aur=""
    if [ "$has_pkgs" = "1" ]; then
      local c name p a b ig
      while IFS='|' read -r c name p a b ig; do
        for v in "${apps[@]}"; do
          if [ "$v" = "$c/$name" ]; then pac="$pac $(missing_of "$p")"; aur="$aur $(missing_of "$a")"; fi
        done
      done <<<"$APPS"
      for c in "${cats[@]}"; do
        entry=$(cat_pkgs "$c")
        pac="$pac $(missing_of "$(echo "${entry%%;*}" | sed 's/^pacman://')")"
        aur="$aur $(missing_of "$(echo "${entry##*;}" | sed 's/^aur://')")"
      done
      pac=$(echo "$pac" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ' || true)
      aur=$(echo "$aur" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ' || true)
    fi

    # step 2: unpick review
    local keep_pac="$pac" keep_aur="$aur"
    if [ -n "$pac$aur" ]; then
      say "Step 2 of $last: review missing packages (unpick to remove):"
      for p in $pac; do d=$(pkg_desc "$p"); say "  $p${d:+ - $d}"; done
      for p in $aur; do say "  (aur) $p"; done
      mapfile -t kept < <(printf '%s\n' $pac $aur | gum choose --no-limit --selected="$(printf '%s\n' $pac $aur | paste -sd,)" --header "Step 2 of 3: unpick to remove" || true)
      keep_pac=""; keep_aur=""
      for p in "${kept[@]:-}"; do
        case " $pac " in *" $p "*) keep_pac="$keep_pac $p" ;; *) keep_aur="$keep_aur $p" ;; esac
      done
    elif [ "${#cats[@]}" -gt 0 ]; then
      say "$({ for c in "${cats[@]}"; do echo "$c"; done; } | tr '\n' ' '): nothing missing, nothing to do."
    fi

    # step 3: decide (cursor starts on Back — ENTER never installs blind)
    say "Step $last of $last: review, then decide"
    say "Mode: $mode"
    [ "$has_pkgs" = "1" ] && { say "pacman: ${keep_pac:-(none missing)}"; say "aur:    ${keep_aur:-(none missing)}"; }
    [ "${#cats[@]}" -gt 0 ] && say "cats:   ${cats[*]}"
    case "$mode" in install+stow | stow)
      say "stow:   ${values[*]}"
      steps="wire git hooks"
      [ "$(current_branch)" = "dynamic" ] && steps="$steps, mark theme local"
      say "steps:  $steps"
      ;;
    esac
    decision=$(gum choose --header "Decide:" "Back to picks" "Execute" "Abort to menu") || return 0
    case "$decision" in "Abort to menu") return 0 ;; "Back to picks") continue ;; esac

    FORCE=0
    if [ "$mode" != "packages" ]; then
      marked=""
      local c name p a b ig
      while IFS='|' read -r c name p a b ig; do
        for v in "${apps[@]}"; do
          [ "$v" = "$c/$name" ] && no_share_file "$c" "$name" >/dev/null && marked="$marked $name"
        done
      done <<<"$APPS"
      [[ " ${cats[*]} " == *" noctalia "* ]] && marked="$marked noctalia"
      if [ -n "$marked" ]; then
        say "Marked .no-share (machine-specific / vendored):$marked"
        gum confirm "Stow these anyway (only on the machine they came from)?" && FORCE=1 || FORCE=0
      fi
    fi

    wire_hooks
    if [ "$has_pkgs" = "1" ]; then install_explicit "$keep_pac" "$keep_aur" || say "package install had errors, continuing to stow."; fi
    if [ "$mode" != "packages" ]; then
      local c name p a b ig
      while IFS='|' read -r c name p a b ig; do
        for v in "${apps[@]}"; do [ "$v" = "$c/$name" ] && stow_app "$c" "$name" "$ig" || true
        done
      done <<<"$APPS"
      for c in "${cats[@]}"; do apply_cat "$c" "$noctalia"; done
      { for v in "${apps[@]}"; do echo "$v"; done; for c in "${cats[@]}"; do echo "@$c"; done; } | record_installed
    fi
    [ "$(current_branch)" = "dynamic" ] && [ "$mode" != "packages" ] && mark_theme_local
    return 0
  done
}

switch_branch() {
  local current order branch
  current=$(current_branch)
  order="master dynamic"
  [ "$current" = "dynamic" ] && order="dynamic master"
  branch=$(gum choose --header "Current branch: $current. Switch to:" $order) || return 0
  [ "$branch" = "$current" ] && return 0
  if run git checkout "$branch"; then
    wire_hooks
    [ "$branch" = "dynamic" ] && mark_theme_local
  else
    say "checkout failed - local changes? resolve and retry."
  fi
}

do_update() {
  gum confirm "Pull, re-wire hooks, re-stow recorded apps?" || return 0
  run git pull --ff-only || true
  wire_hooks
  [ "$(current_branch)" = "dynamic" ] && mark_theme_local
  FORCE=1
  while IFS='|' read -r c name; do
    [ -n "$c" ] || continue
    while IFS='|' read -r cc nn pp aa bb ig; do
      [ "$cc/$nn" = "$c/$name" ] && stow_app "$cc" "$nn" "$ig" || true
    done <<<"$APPS"
  done < <(recorded_apps)
  while read -r c; do [ -n "$c" ] && apply_cat "$c" ""; done < <(recorded_cats)
  while read -r c; do
    [ -n "$c" ] || continue
    if is_install_cat "$c"; then
      entry=$(cat_pkgs "$c")
      pac_list=$(missing_of "$(echo "${entry%%;*}" | sed 's/^pacman://')")
      aur_list=$(missing_of "$(echo "${entry##*;}" | sed 's/^aur://')")
      install_explicit "$pac_list" "$aur_list"
    fi
  done < <(recorded_cats)
  say "Update done."
}

do_validate() {
  local branch fail=0
  branch=$(current_branch)
  pass() { gum style --foreground 2 "PASS    $1  $2"; }
  warn() { gum style --foreground 3 "WARNING $1  $2"; }
  err() { gum style --foreground 1 "ERROR   $1  $2"; fail=1; }
  case "$branch" in master | dynamic) pass branch "$branch" ;; "") err branch "detached HEAD or not a repo" ;; *) warn branch "on '$branch', not master/dynamic" ;; esac
  [ "$(git config core.hooksPath)" = "scripts/git-hooks" ] && pass "git hooks" "core.hooksPath -> scripts/git-hooks" || err "git hooks" "not set; run any installer op"
  [ -x scripts/git-hooks/post-checkout ] && pass "post-checkout hook" "present + executable" || err "post-checkout hook" "missing or not executable"
  for tool in stow git pacman; do
    command -v "$tool" >/dev/null 2>&1 && pass "$tool" "found" || err "$tool" "missing"
  done
  command -v yay >/dev/null 2>&1 && pass "yay" "found" || warn "yay" "missing (needed for AUR pkgs)"
  if [ "$branch" = "dynamic" ]; then
    expected=$(sed -n 's/^[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' scripts/mark-theme-local.sh)
    marked=$(git ls-files -v | grep '^S' | sed 's/^S //')
    missing=$(comm -23 <(echo "$expected" | sort) <(echo "$marked" | sort))
    if [ -z "$expected" ]; then warn "skip-worktree themes" "no paths in mark-theme-local.sh"
    elif [ -z "$missing" ]; then pass "skip-worktree themes" "all marked"
    else
      warn "skip-worktree themes" "$(echo "$missing" | wc -l) unmarked: $(echo "$missing" | head -3 | tr '\n' ' ')"
      while read -r m; do [ -e "$m" ] || err "theme file missing" "$m listed but not on disk"; done <<<"$missing"
    fi
  fi
  if [ -n "$(recorded_apps)" ]; then
    while IFS='|' read -r c name; do
      [ -n "$c" ] || continue
      pkg="$ROOT/apps/$c/$name"
      [ -d "$pkg" ] || { err "$name files" "$pkg missing"; continue; }
      for child in "$pkg"/*; do
        base=$(basename "$child")
        case "$base" in .no-share | .do-not-stow.md | .git*) continue ;; esac
        if [ -L "$HOME/$base" ]; then
          [ -e "$HOME/$base" ] && pass "$name -> $base" "symlink ok" || err "$name -> $base" "broken symlink"
        elif [ -e "$HOME/$base" ]; then warn "$name -> $base" "exists, not a symlink"
        else warn "$name -> $base" "not linked"
        fi
      done
    done < <(recorded_apps)
  else
    warn "installed apps" "no record yet; apply dotfiles first"
  fi
  [ "$fail" = "0" ] || say "Validate finished with errors."
}

main() {
  logfile
  while true; do
    branch=$(current_branch)
    hooks="NOT WIRED"
    [ "$(git config core.hooksPath)" = "scripts/git-hooks" ] && hooks="wired"
    recorded=$(recorded_apps | wc -l)
    gum style --bold "Paul dotfiles installer"
    say "branch: $branch | hooks: $hooks | recorded apps: $recorded"
    choice=$(gum choose --header "What do you want to do?" \
      "Full install: packages + dotfiles + hooks" \
      "Install packages only: choose apps and categories" \
      "Apply dotfiles only: symlink configs" \
      "Switch branch: master or dynamic" \
      "Update setup: pull, rewire, redo recorded" \
      "Validate system: PASS/WARNING/ERROR" \
      "Exit: quit installer") || break
    case "$choice" in
    "Full install"*) run_pick "install+stow" ;;
    "Install packages only"*) run_pick "packages" ;;
    "Apply dotfiles only"*) run_pick "stow" ;;
    "Switch branch"*) switch_branch ;;
    "Update setup"*) do_update ;;
    "Validate system"*) do_validate ;;
    "Exit"*) break ;;
    esac
    say "────────────────────────────────────────"
  done
  say "Done."
}

FORCE=0
main "$@"

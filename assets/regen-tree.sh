#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/dotfiles-pub"
HTML="$ROOT/dotfiles_tree_structure.html"

sections=(
  "wm:<!-- gen-start -->:<!-- gen-end -->"
  "bar:<!-- gen-start-bar -->:<!-- gen-end-bar -->"
  "term:<!-- gen-start-term -->:<!-- gen-end-term -->"
  "cli:<!-- gen-start-cli -->:<!-- gen-end-cli -->"
  "editor:<!-- gen-start-editor -->:<!-- gen-end-editor -->"
  "misc:<!-- gen-start-misc -->:<!-- gen-end-misc -->"
  "theme:<!-- gen-start-theme -->:<!-- gen-end-theme -->"
  "overlay:<!-- gen-start-overlay -->:<!-- gen-end-overlay -->"
  "nix:<!-- gen-start-nix -->:<!-- gen-end-nix -->"
  "root:<!-- gen-start-root -->:<!-- gen-end-root -->"
)

content=$(cat "$HTML")

for s in "${sections[@]}"; do
  sec="${s%%:*}"
  rest="${s#*:}"
  start="${rest%%:*}"
  end="${rest#*:}"
  out=$("$ROOT/assets/gen-tree.sh" "$ROOT" "$sec")
  content=$(printf '%s\n' "$content" | awk -v start="$start" -v end="$end" -v repl="$out" '
    BEGIN { inblock=0 }
    $0 ~ start { print; print repl; inblock=1; next }
    $0 ~ end { inblock=0 }
    !inblock { print }
  ')
done

printf '%s\n' "$content" > "$HTML"
echo "Regenerated $HTML"
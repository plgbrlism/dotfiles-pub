"""gtk and qt setup, plus theme skip-worktree bits"""
import subprocess

from . import paths, ui

def script_for(name: str) -> str:
    return f"{name}/setup-{name}.sh"


def run_script(rel: str) -> int:
    script = paths.root / rel
    if not script.exists():
        ui.warn(f"{rel} not found, skipped")
        return 1
    return ui.stream(["bash", str(script)])


def setup(names: list[str]) -> int:
    rc = 0
    for name in names:
        ui.head(f"{name} setup")
        rc |= run_script(script_for(name))
    return rc


def mark_bit(on: bool) -> int:
    """skip-worktree keeps rizzoo outputs machine-local so status stays clean"""
    helper = paths.root / "scripts/mark-theme-local.sh"
    if not helper.exists():
        ui.warn("scripts/mark-theme-local.sh not found, theme bits not applied")
        return 1
    if on:
        return ui.stream(["bash", str(helper)])
    paths_l = theme_paths()
    if not paths_l:
        return 0
    # paths hold no spaces, word splitting intended
    return subprocess.run(["git", "-C", str(paths.root), "update-index",
                           "--no-skip-worktree", "--", *paths_l]).returncode


def theme_paths() -> list[str]:
    """quoted paths listed in the helper script, the single source of truth"""
    helper = paths.root / "scripts/mark-theme-local.sh"
    if not helper.exists():
        return []
    out = []
    grab = False
    for line in helper.read_text().splitlines():
        line = line.strip()
        if line.startswith("git update-index"):
            grab = True
        if grab and line.startswith('"'):
            out.append(line.split('"')[1])
    return out


def skip_count() -> int:
    r = subprocess.run(["git", "-C", str(paths.root), "ls-files", "-v"],
                       capture_output=True, text=True)
    return sum(1 for l in r.stdout.splitlines() if l.startswith("S"))


def apply_bits(branch: str) -> None:
    """only dynamic carries rizzoo baselines, master keeps tracked content live"""
    if branch == "dynamic":
        mark_bit(True)
    else:
        mark_bit(False)


def hooks_dir() -> paths.Path:
    return paths.here / "hooks"


def hooks_wired() -> bool:
    r = subprocess.run(["git", "-C", str(paths.root), "config", "core.hooksPath"],
                       capture_output=True, text=True)
    return r.stdout.strip() == str(hooks_dir())


def install_hooks() -> int:
    d = hooks_dir()
    d.mkdir(parents=True, exist_ok=True)
    for hook in (d / "post-checkout",):
        hook.write_text(_hook_src())
        hook.chmod(0o755)
    r = subprocess.run(["git", "-C", str(paths.root), "config", "core.hooksPath", str(d)])
    if r.returncode == 0:
        ui.ok(f"hooksPath -> {d}")
    return r.returncode


def _hook_src() -> str:
    return """#!/usr/bin/env bash
set -euo pipefail
# reinstall theme skip-worktree bits after a branch checkout.
# $1=prev $2=new $3=flag, flag 1 is a branch checkout.
[ "${3:-0}" = "1" ] || exit 0
ROOT="$(git rev-parse --show-toplevel)"
# quiet, never blocks a checkout
"$ROOT/install.sh" theme-bits >/dev/null 2>&1 || true
"""
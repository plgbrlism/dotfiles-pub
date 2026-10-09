"""fzf-backed UI for the installer.

Every screen is an fzf popup: arrows move, typing filters, ENTER chooses,
ESC or ctrl-c backs out. Multi-pick screens are baskets: ENTER toggles a
line (visible [x]/[ ]), the Done line confirms. No space key, no number
keys, no python UI dependency.

The only subprocess seam is _run(); tests swap it out.
"""
from __future__ import annotations

import shutil
import subprocess
import sys

DONE = "__done__"

ORANGE = "\033[38;5;208m"
BLUE = "\033[34m"
DIM = "\033[2m"
BOLD = "\033[1m"
YELLOW = "\033[33m"
GREEN = "\033[32m"
RED = "\033[31m"
RESET = "\033[0m"

_COLORS = (
    "fg:#e6e1d5,bg:-1,hl:#ff9d00,fg+:#e6e1d5,bg+:#3a3226,"
    "hl+:#ff9d00,info:#6c7a89,prompt:#ff9d00,pointer:#ff9d00,"
    "marker:#ff9d00,header:#6c7a89,border:#6c7a89"
)

CANNOT_SORT = "--no-sort"


def have_fzf() -> bool:
    return shutil.which("fzf") is not None


def say(text: str = "", color: str | None = None) -> None:
    if color and sys.stdout.isatty():
        print(f"{color}{text}{RESET}")
    else:
        print(text)


def _run(argv: list[str], input_text: str) -> tuple[int, str]:
    """The single fzf seam. Returns (exit code, stdout). 130 = cancelled."""
    try:
        proc = subprocess.run(argv, input=input_text, capture_output=True, text=True)
    except FileNotFoundError:
        print("fzf not found. Install it: sudo pacman -S fzf", file=sys.stderr)
        raise SystemExit(1)
    return proc.returncode, proc.stdout


def _lines(entries) -> str:
    return "\n".join(f"{value}\t{label}" for value, label in entries)


def pick(title: str, entries: list[tuple[str, str]], preview: str | None = None) -> str | None:
    """One fzf screen. Returns the chosen value, or None on ESC/ctrl-c."""
    argv = [
        "fzf",
        "--delimiter", "\t",
        "--with-nth", "2..",
        CANNOT_SORT,
        "--reverse",
        "--height", "~60%",
        "--min-height", "10",
        "--cycle",
        "--prompt", "> ",
        "--pointer", ">",
        "--header", title,
        "--color", _COLORS,
    ]
    if preview:
        argv += ["--preview", preview, "--preview-window", "right,45%,wrap"]
    rc, out = _run(argv, _lines(entries))
    if rc != 0 or not out:
        return None
    return out.split("\t", 1)[0]


def confirm(title: str, default: bool = False) -> bool:
    entries = [("yes", "Yes"), ("no", "No")]
    if not default:
        entries.reverse()
    return pick(title, entries) == "yes"


def basket(title: str, entries: list[tuple[str, str]], initial: tuple = (),
           preview: str | None = None) -> list[str] | None:
    """Multi-pick over single-select screens. Returns picked values or None."""
    picked = [v for v in initial if v in dict(entries)]
    hint = ""
    while True:
        rows: list[tuple[str, str]] = []
        if picked:
            rows.append((DONE, f"Done ({len(picked)} picked) -> continue"))
        else:
            rows.append((DONE, "Done (nothing picked)"))
        for value, label in entries:
            mark = "[x]" if value in picked else "[ ]"
            rows.append((value, f"{mark} {label}"))
        ans = pick(f"{title}{hint}", rows, preview=preview)
        if ans is None:
            return None
        if ans == DONE:
            if picked:
                return picked
            hint = "  [nothing picked yet]"
            continue
        if ans in picked:
            picked = [v for v in picked if v != ans]
        else:
            picked.append(ans)

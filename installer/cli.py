"""fzf CLI for the Paul dotfiles installer.

One navigation model on every screen: arrows move, typing filters, ENTER
chooses, ESC or ctrl-c backs out. Multi-pick screens are baskets: ENTER
toggles an entry (never confirms), the Done entry confirms. There is no
space key anywhere.
"""
from __future__ import annotations

import socket
import sys

from . import fzfui, ops
from .fzfui import DONE
from .apps import APPS, CATEGORIES, INSTALL_CATS, SPECIAL_CATS, apps_in

APP_BY_KEY = {(a.cat, a.name): a for a in APPS}

STEP = fzfui.ORANGE
DIM = fzfui.DIM

ENTER_CHOOSES = "ENTER toggles, Done confirms, ESC or ctrl-c backs out"

PREVIEW = "pacman -Si {1} 2>/dev/null | head -25 || echo 'not in sync repos'"


def _installed_cache() -> dict:
    pkgs = [p for a in APPS for p in a.pacman + a.aur]
    cache = ops.batch_pkg_status(pkgs)
    for app in APPS:
        if app.bin:
            cache[app.bin] = ops.have(app.bin)
    return cache


def _label(app, cache: dict) -> str:
    if app.bin and cache.get(app.bin):
        return f"{app.name} (installed)"
    if (app.pacman or app.aur) and all(cache.get(p) for p in app.pacman + app.aur):
        return f"{app.name} (installed)"
    return app.name


def selected_apps(picked: list[str]) -> list:
    out = []
    for item in picked:
        if "|" in item:
            cat, name = item.split("|", 1)
            app = APP_BY_KEY.get((cat, name))
            if app:
                out.append(app)
    return out


def _cat_entries() -> list[tuple[str, str]]:
    """(value, label) for the category basket, in menu order."""
    cache = _installed_cache()
    entries = []
    for cat in CATEGORIES:
        apps = apps_in(cat)
        if cat in SPECIAL_CATS or not apps:
            if cat in ("gtk", "qt"):
                note = " (do not stow)"
            elif cat in INSTALL_CATS:
                note = " (packages only)"
            else:
                note = ""
            entries.append((cat, f"{cat}/  (whole category){note}"))
        else:
            for app in apps:
                entries.append((f"{cat}|{app.name}", f"{cat}/{_label(app, cache)}"))
    return entries


def basket_pick(title: str, items: list[tuple], initial: tuple = (),
                preview: str | None = None) -> list | None:
    return fzfui.basket(title, items, initial, preview=preview)


def _apply(picked: list[str], mode: str, noctalia: str | None, force: bool,
           explicit: dict[str, list[str]] | None = None) -> None:
    apps = selected_apps(picked)
    cats = {i for i in picked if "|" not in i}
    if mode in ("install+stow", "packages"):
        if explicit is not None:
            ops.install_packages(apps, print)
            ops.install_explicit(explicit.get("pacman", []), explicit.get("aur", []), print)
        else:
            ops.install_packages(apps, cats, print)
    if mode in ("install+stow", "stow"):
        for app in apps:
            ops.stow_app(app, print, force=force)
        for cat in sorted(cats):
            ops.apply_cat(cat, print, noctalia, force=force)
        ops.record_installed(apps, cats)


def _print_review(pac: list[str], aur: list[str]) -> None:
    info = ops.batch_pkg_info(pac)
    if pac:
        fzfui.say("pacman:", fzfui.BOLD)
        for p in pac:
            desc = info.get(p, "")
            fzfui.say(f"  {p}" + (f" - {desc}" if desc else ""))
    if aur:
        fzfui.say("aur (names only):", fzfui.BOLD)
        for p in aur:
            fzfui.say(f"  {p}")


def _decide(summary: str) -> str | None:
    """Review gate. Safe order: cursor starts on Back, ENTER never installs blind."""
    fzfui.say(summary, fzfui.BOLD)
    return fzfui.pick(
        "Decide:",
        [("back", "Back to picks"),
         ("execute", "Execute"),
         ("abort", "Abort to menu")],
    )


def run_pick(mode: str) -> None:
    has_pkgs = mode in ("install+stow", "packages")
    last = "3" if has_pkgs else "2"
    while True:
        picked = basket_pick(f"Step 1 of {last}: choose apps/categories", _cat_entries())
        if picked is None:
            return
        apps = selected_apps(picked)
        cats = {i for i in picked if "|" not in i}

        noctalia = None
        if "noctalia" in picked:
            noctalia = fzfui.pick(
                "Which machine for noctalia?",
                [("dell", "dell"), ("hp", "hp")],
            )
            if noctalia is None:
                continue

        explicit: dict[str, list[str]] | None = None
        if has_pkgs:
            plan = ops.plan_install(apps, cats)
            npac, naur = len(plan["pacman"]), len(plan["aur"])
            if npac or naur:
                fzfui.say(
                    f"\nStep 2 of {last}: review {npac} pacman + {naur} aur missing "
                    f"(present ones hidden):",
                    STEP,
                )
                _print_review(plan["pacman"], plan["aur"])
                pac_set = set(plan["pacman"])
                aur_set = set(plan["aur"])
                items = [(p, p) for p in plan["pacman"]] + [(p, p) for p in plan["aur"]]
                kept = basket_pick("Step 2 of 3: unpick to remove",
                                   items, initial=tuple(v for v, _ in items),
                                   preview=PREVIEW)
                if kept is None:
                    continue
                explicit = {
                    "pacman": sorted(n for n in kept if n in pac_set),
                    "aur": sorted(n for n in kept if n in aur_set),
                }
            elif cats:
                full = ops.cat_pkgs(cats)
                versions = ops.batch_pkg_versions(full["pacman"] + full["aur"])
                if versions:
                    fzfui.say(
                        f"{', '.join(sorted(cats))}: "
                        f"{len(versions)}/{len(versions)} present, nothing to do.",
                        fzfui.BOLD,
                    )
                    for name in sorted(versions):
                        fzfui.say(f"  {name} {versions[name] or '(unknown version)'}")

        lines = [f"\nStep {last} of {last}: review, then decide", f"Mode: {mode}"]
        if has_pkgs:
            pac = explicit["pacman"] if explicit is not None else plan["pacman"]
            aur = explicit["aur"] if explicit is not None else plan["aur"]
            lines.append("pacman: " + (" ".join(pac) or "(none missing)"))
            lines.append("aur:    " + (" ".join(aur) or "(none missing)"))
            if cats:
                lines.append("cats:   " + ", ".join(sorted(cats)))
        if mode in ("install+stow", "stow"):
            lines.append("stow:   " + ", ".join(sorted(i.replace("|", "/") for i in picked)))
            steps = ["wire git hooks"]
            if ops.current_branch() == "dynamic":
                steps.append("mark theme local")
            lines.append("steps:  " + ", ".join(steps))
        decision = _decide("\n".join(lines))
        if decision is None or decision == "abort":
            return
        if decision == "back":
            continue

        force = False
        if mode != "packages":
            marked = [a.name for a in apps if ops.no_share_file(a)]
            if "noctalia" in cats:
                marked.append("noctalia")
            if marked:
                fzfui.say(
                    "Marked .no-share (machine-specific / vendored): " + ", ".join(marked),
                    fzfui.YELLOW,
                )
                force = fzfui.confirm(
                    "Stow these anyway (only on the machine they came from)?",
                    default=False,
                )

        ops.wire_hooks()
        print("git: core.hooksPath -> scripts/git-hooks")
        _apply(picked, mode, noctalia, force, explicit)
        if mode != "packages" and ops.current_branch() == "dynamic":
            ops.mark_theme_local(print)
        return


def switch_branch() -> None:
    current = ops.current_branch()
    order = ["master", "dynamic"]
    if current in order:
        order.remove(current)
        order.insert(0, current)
    branch = fzfui.pick(
        f"Current branch: {current}. Switch to:",
        [(b, b) for b in order],
    )
    if branch is None or branch == current:
        return
    if ops.checkout(branch, print) == 0:
        ops.wire_hooks()
        print("git: core.hooksPath -> scripts/git-hooks")
        if branch == "dynamic":
            ops.mark_theme_local(print)
    else:
        print("checkout failed - local changes? resolve and retry.")


def update() -> None:
    if fzfui.confirm("Pull, re-wire hooks, re-stow recorded apps?", default=False):
        ops.pull(print)
        ops.wire_hooks()
        print("git: core.hooksPath -> scripts/git-hooks")
        if ops.current_branch() == "dynamic":
            ops.mark_theme_local(print)
        apps = ops.recorded_apps()
        if apps:
            print(f"Re-stowing {len(apps)} recorded apps...")
            for app in apps:
                ops.stow_app(app, print, force=True)
        else:
            print("No recorded apps.")
        for cat in ops.recorded_cats():
            ops.apply_cat(cat, print, force=True)
        cats = ops.recorded_cats()
        if any(c in INSTALL_CATS for c in cats):
            ops.install_packages([], cats, print)


def update_nixos() -> None:
    if not fzfui.confirm("Pull, re-wire hooks, and rebuild the system?", default=False):
        return
    ops.pull(print)
    ops.wire_hooks()
    print("git: core.hooksPath -> scripts/git-hooks")
    if ops.current_branch() == "dynamic":
        ops.mark_theme_local(print)
    hosts = ops.hosts()
    if not hosts:
        print("No hosts under nix/hosts.")
        return
    host = _pick_host(hosts)
    if host is None:
        return
    ops.rebuild(host, print)
    ops.record_rebuild(host)


def _pick_host(hosts: list[str]) -> str | None:
    order = list(hosts)
    name = socket.gethostname()
    if name in order:
        order.remove(name)
        order.insert(0, name)
    return fzfui.pick("Which host?", [(h, h) for h in order])


def rebuild_system() -> None:
    hosts = ops.hosts()
    if not hosts:
        print("No hosts under nix/hosts.")
        return
    host = _pick_host(hosts)
    if host is None:
        return
    if not fzfui.confirm(f"Run nixos-rebuild switch --flake nix#{host}?", default=False):
        return
    if ops.rebuild(host, print) == 0:
        ops.record_rebuild(host)
    else:
        print("rebuild failed - see output above.")


def validate() -> None:
    colors = {"PASS": fzfui.GREEN, "WARNING": fzfui.YELLOW, "ERROR": fzfui.RED}
    for level, item, detail in ops.validate():
        fzfui.say(f"{level:<7} {item:<22} {detail}", colors.get(level))


def _status() -> str:
    branch = ops.current_branch() or "?"
    hooks = "wired" if ops.hooks_wired() else "NOT WIRED"
    line = f"distro: {ops.distro()} | branch: {branch} | hooks: {hooks}"
    if ops.distro() == "nixos":
        hosts = ", ".join(ops.hosts()) or "-"
        return line + f" | hosts: {hosts}"
    return line + f" | recorded apps: {len(ops.recorded_apps())}"


ARCH_MENU = [
    ("full", "Full install: packages + dotfiles + hooks"),
    ("pkgs", "Install packages only: choose apps and categories"),
    ("stow", "Apply dotfiles only: symlink configs"),
    ("branch", "Switch branch: master or dynamic"),
    ("update", "Update setup: pull, rewire, redo recorded"),
    ("validate", "Validate system: PASS/WARNING/ERROR"),
    ("exit", "Exit: quit installer"),
]

NIXOS_MENU = [
    ("branch", "Switch branch: master or dynamic"),
    ("rebuild", "Rebuild system: nixos-rebuild switch"),
    ("update", "Update setup: pull, rewire, rebuild"),
    ("validate", "Validate system: nix, flake, hosts"),
    ("exit", "Exit: quit installer"),
]

ARCH_ACTIONS = {
    "full": lambda: run_pick("install+stow"),
    "pkgs": lambda: run_pick("packages"),
    "stow": lambda: run_pick("stow"),
    "branch": switch_branch,
    "update": update,
    "validate": validate,
}

NIXOS_ACTIONS = {
    "branch": switch_branch,
    "rebuild": rebuild_system,
    "update": update_nixos,
    "validate": validate,
}


def _rule() -> None:
    fzfui.say("─" * 40, DIM)


def main() -> None:
    if not sys.stdin.isatty():
        print("installer needs a terminal (stdin is not a tty).", file=sys.stderr)
        raise SystemExit(1)
    if not fzfui.have_fzf():
        print("fzf not found. Install it: sudo pacman -S fzf", file=sys.stderr)
        raise SystemExit(1)

    is_nixos = ops.distro() == "nixos"
    menu = NIXOS_MENU if is_nixos else ARCH_MENU
    actions = NIXOS_ACTIONS if is_nixos else ARCH_ACTIONS

    while True:
        fzfui.say("\nPaul dotfiles installer", STEP)
        fzfui.say(_status())
        choice = fzfui.pick("What do you want to do?", menu)
        if choice is None or choice == "exit":
            break
        try:
            actions[choice]()
        except KeyboardInterrupt:
            print("\nCancelled.")
        _rule()
    print("Done.")


if __name__ == "__main__":
    main()

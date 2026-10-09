"""read-only validation pass"""
import shutil

from . import manifest, paths, pkg, repo, stow, theme, ui

ok, warn, bad = "ok", "warn", "bad"


def add(rows: list, level: str, item: str, note: str = "") -> None:
    rows.append((level, item, note))


def run() -> list[tuple]:
    rows: list[tuple] = []
    b = repo.branch()
    add(rows, ok if b else bad, "branch", b or "detached head")

    if theme.hooks_wired():
        add(rows, ok, "hooks", "core.hooksPath set")
    else:
        add(rows, warn, "hooks", "hooksPath not wired, run hooks step")

    for tool in ("git", "stow"):
        add(rows, ok if shutil.which(tool) else bad, f"bin {tool}",
            shutil.which(tool) or "missing")

    h = pkg.aur_helper()
    add(rows, ok if h else warn, "aur helper", h or "none, will be built on demand")

    _packages(rows)
    _links(rows)
    _app_bins(rows)

    if b == "dynamic":
        cnt = theme.skip_count()
        want = len(theme.theme_paths())
        lvl = ok if cnt >= want else warn
        add(rows, lvl, "theme bits", f"{cnt} of {want} skip-worktree")

    _trim(rows)
    return rows


def _packages(rows: list) -> None:
    from . import manifest as m
    apps = m.apps()
    miss = pkg.missing([p for a in apps for p in a.pacman])
    add(rows, ok if not miss else warn, "app packages",
        "all installed" if not miss else f"{len(miss)} missing")
    for g, pac, _ in m.groups():
        miss = pkg.missing(pac)
        add(rows, ok if not miss else warn, f"group {g}",
            "all installed" if not miss else f"{len(miss)} missing")


def _links(rows: list) -> None:
    broken, foreign, good = [], [], 0
    for kind, a in stow.all_pkgs():
        if kind == "cat":
            continue
        src = a.pkg
        if not src.is_dir():
            continue
        for child in src.iterdir():
            if child.name in stow.never_stow or child.name.startswith(".git"):
                continue
            state = stow.link_state(paths.home / child.name)
            if state == "good":
                good += 1
            elif state == "broken":
                broken.append(child.name)
            elif state == "foreign":
                foreign.append(child.name)
    add(rows, ok if not broken else warn, "links",
        f"{good} ok, {len(broken)} broken, {len(foreign)} unlinked")
    for name in broken[:10]:
        add(rows, warn, "broken link", name)


def _app_bins(rows: list) -> None:
    miss = [a.name for a in manifest.apps() if a.bin and not shutil.which(a.bin)]
    add(rows, ok if not miss else warn, "app binaries",
        "all present" if not miss else ", ".join(miss[:8]))


def _trim(rows: list) -> None:
    """keep output short: one line per level past the first"""
    seen: dict[str, int] = {}
    keep = []
    for lvl, item, note in rows:
        if lvl == ok:
            continue
        seen[item] = seen.get(item, 0) + 1
        if seen[item] <= 3:
            keep.append((lvl, item, note))
    rows[:] = [r for r in rows if r[0] == ok] + keep
    rows.sort(key=lambda r: {bad: 0, warn: 1, ok: 2}[r[0]])


def report(rows: list) -> bool:
    if not rows:
        ui.ok("nothing to check")
        return True
    t = ui.table([("", {"style": "bold"}), ("item", {"style": "bold"}), ("note", {})],
                 [(f"[{'ok' if l == ok else 'warn' if l == warn else 'bad'}]{l}[/]", i, n)
                  for l, i, n in rows])
    ui.console.print(t)
    bads = sum(1 for l, _, _ in rows if l == bad)
    warns = sum(1 for l, _, _ in rows if l == warn)
    ui.say()
    if bads:
        ui.bad(f"{bads} failing, {warns} warning")
    elif warns:
        ui.warn(f"{warns} warning, 0 failing")
    else:
        ui.ok("all checks pass")
    return bads == 0
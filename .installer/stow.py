"""stow configs into home"""
import shutil

from . import paths, ui

never_stow = {".no-share", ".do-not-stow.md", "SHARE-WARNING.md", "__pycache__"}


def eff_ignore(a) -> str:
    pat = "|".join(sorted(never_stow | {p for p in a.ignore.split(",") if p}))
    return f"--ignore={pat}"


def backup_conflicts(pkg) -> None:
    """move real files that block a link aside, never touch dirs or symlinks"""
    for child in sorted(pkg.iterdir()):
        if child.name in never_stow or child.name.startswith(".git"):
            continue
        target = paths.home / child.name
        if target.exists() and not target.is_symlink():
            shutil.move(str(target), target.with_name(target.name + ".bak"))
            ui.note(f"backed up {target.name} to {target.name}.bak")


def warn_no_share(name: str, scope) -> None:
    doc = scope / ".do-not-stow.md"
    if doc.exists():
        ui.note(doc.read_text().strip())
    ui.warn(f"{name}: .no-share at {scope.name}/, skipped")


def stow_pkg(a, force: bool = False) -> int:
    """one stow package, .no-share gated"""
    if not a.pkg.is_dir():
        ui.warn(f"{a.name}: {a.pkg.name} not found, skipped")
        return 1
    if not force:
        for scope in (a.dir, a.pkg):
            if scope.joinpath(".no-share").exists():
                warn_no_share(a.name, scope)
                return 0
    backup_conflicts(a.pkg)
    return ui.stream(["stow", "-d", str(a.dir if a.cat else a.pkg.parent),
                      "-t", str(paths.home), eff_ignore(a), a.name])


def stow_cat(cat: str) -> int:
    """whole apps/<cat> as one unit, for @dir rows"""
    src = paths.root / "apps" / cat
    if not src.is_dir():
        return 0
    return ui.stream(["stow", "-d", str(paths.root / "apps"), "-t", str(paths.home), cat])


def stow_top(a, force: bool = False) -> int:
    """dir stowed from repo root"""
    if not force and a.pkg.joinpath(".no-share").exists():
        warn_no_share(a.name, a.pkg)
        return 0
    backup_conflicts(a.pkg)
    return ui.stream(["stow", "-d", str(paths.root), "-t", str(paths.home),
                      eff_ignore(a), a.name])


def all_pkgs():
    """every stowable unit: manifest apps, @dir cats, root dirs"""
    from . import manifest
    units = []
    for a in manifest.apps():
        if not a.stowable:
            continue
        units.append(("cat", a.cat) if a.name.startswith("@") else ("pkg", a))
    for a in manifest.top_stow():
        units.append(("top", a))
    return units


def apply(kind: str, a, force: bool = False) -> int:
    if kind == "cat":
        return stow_cat(a)
    if kind == "top":
        return stow_top(a, force)
    return stow_pkg(a, force)


def link_state(path) -> str:
    """good, broken, foreign, or none"""
    if path.is_symlink():
        return "good" if path.exists() else "broken"
    if path.exists():
        return "foreign"
    return "none"


def repair(a) -> int:
    """drop broken symlinks only, real files and good links stay"""
    cnt = 0
    for child in sorted(a.pkg.iterdir()):
        if child.name in never_stow or child.name.startswith(".git"):
            continue
        target = paths.home / child.name
        if link_state(target) == "broken":
            target.unlink()
            ui.note(f"removed broken link {target}")
            cnt += 1
    return cnt
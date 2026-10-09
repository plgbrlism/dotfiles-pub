"""preflight checks before touching anything"""
import shutil

from . import paths, pkg, repo, ui

need = ("git", "stow", "sudo")


def run() -> bool:
    rows = []
    for t in need:
        rows.append((t, shutil.which(t)))
    missing = [t for t, p in rows if not p]

    if pkg.is_nixos():
        ui.warn("nixos detected: packages are declarative, use rebuild nixos")
        if not shutil.which("nixos-rebuild"):
            missing.append("nixos-rebuild")

    for t, p in rows:
        if p:
            ui.ok(f"{t:<10} {p}")
        else:
            ui.bad(f"{t:<10} missing")

    b = repo.branch()
    ui.ok(f"{'branch':<10} {b or 'detached'}")
    if repo.is_dirty():
        ui.warn("worktree has local changes, stow will still run")

    if not paths.manifests.joinpath("apps.txt").exists():
        ui.bad("manifests/apps.txt not found")
        return False

    if missing:
        ui.say()
        ui.warn(f"missing: {' '.join(missing)}")
        if t_hint := _hint(missing):
            ui.note(t_hint)
        return False
    return True


def _hint(missing: list[str]) -> str | None:
    if set(missing) & {"git", "stow", "sudo"}:
        return "sudo pacman -S --needed git stow"
    return None
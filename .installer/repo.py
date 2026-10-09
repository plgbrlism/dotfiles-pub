"""repo state: branch, pull, hosts, rebuild"""
import subprocess

from . import paths, pkg, ui


def git(*args: str) -> int:
    return ui.stream(["git", "-C", str(paths.root), *args])


def branch() -> str:
    r = subprocess.run(["git", "-C", str(paths.root), "branch", "--show-current"],
                       capture_output=True, text=True)
    return r.stdout.strip()


def is_dirty() -> bool:
    r = subprocess.run(["git", "-C", str(paths.root), "status", "--porcelain"],
                       capture_output=True, text=True)
    return bool(r.stdout.strip())


def pull() -> int:
    if is_dirty():
        ui.warn("worktree dirty, not pulling")
        return 1
    return git("pull", "--ff-only")


def hosts() -> list[str]:
    d = paths.root / "nix" / "hosts"
    if not d.is_dir():
        return []
    return sorted(p.name for p in d.iterdir() if p.is_dir())


def rebuild(host: str) -> int:
    if not pkg.is_nixos():
        ui.warn("not nixos, nothing to rebuild")
        return 1
    if not ui.confirm(f"rebuild nixos for host {host}?"):
        return 0
    return ui.stream(["sudo", "nixos-rebuild", "switch", "--flake", f"{paths.root}#{host}"])
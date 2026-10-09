"""package install, missing-only"""
import shutil
import subprocess

from . import paths, ui

probe: dict[str, bool] = {}


def is_nixos() -> bool:
    if paths.Path("/etc/NIXOS").exists():
        return True
    try:
        return "ID=nixos" in paths.Path("/etc/os-release").read_text()
    except OSError:
        return False


def have(pkg: str) -> bool:
    """cached pacman -Q probe, one subprocess per package for the whole run"""
    if pkg not in probe:
        probe[pkg] = subprocess.run(["pacman", "-Q", "--quiet", pkg],
                                     capture_output=True).returncode == 0
    return probe[pkg]


def missing(pkgs) -> list[str]:
    return sorted({p for p in pkgs if not have(p)})


def plan(pacs, aurs) -> dict:
    """missing-only plan, one cached probe per package"""
    return {"pacman": missing(pacs), "aur": missing(aurs)}


def aur_helper() -> str | None:
    for h in ("yay", "paru"):
        if shutil.which(h):
            return h
    return None


def ensure_helper() -> str | None:
    h = aur_helper()
    if h:
        return h
    ui.warn("no aur helper, building yay-bin")
    ui.stream(["sudo", "pacman", "-S", "--needed", "--noconfirm", "base-devel", "git"])
    d = paths.Path("/tmp/opencode/yay-bin")
    shutil.rmtree(d, ignore_errors=True)
    if ui.stream(["git", "clone", "https://aur.archlinux.org/yay-bin.git", str(d)]):
        return None
    if ui.stream(["makepkg", "-si", "--noconfirm"], cwd=d):
        return None
    return aur_helper()


def install(pacs: list[str], aurs: list[str], empty: str = "nothing to install") -> int:
    if not pacs and not aurs:
        ui.ok(empty)
        return 0
    ui.stream(["sudo", "-v"])
    if pacs and ui.stream(["sudo", "pacman", "-S", "--needed", "--noconfirm", *pacs]):
        return 1
    if aurs:
        h = ensure_helper()
        if not h:
            ui.bad("no aur helper available")
            return 1
        if ui.stream([h, "-S", "--needed", "--noconfirm", *aurs]):
            return 1
    return 0
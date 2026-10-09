"""All side-effecting operations: git, packages, stow, validation, logging."""
from __future__ import annotations

import os
import shutil
import subprocess
import time
from pathlib import Path

from .apps import APPS, App

ROOT = Path(__file__).resolve().parent.parent
HOME = Path.home()
STATE_DIR = Path.home() / ".local" / "state" / "paul-dotfiles-installer"
STATE_FILE = STATE_DIR / "installed.txt"


def log_path() -> Path:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    return STATE_DIR / f"{time.strftime('%Y%m%d-%H%M%S')}.log"


_LOGFILE: Path | None = None


def _file_log(line: str) -> None:
    global _LOGFILE
    try:
        if _LOGFILE is None:
            _LOGFILE = log_path()
        assert _LOGFILE is not None
        with _LOGFILE.open("a") as f:
            f.write(line + "\n")
    except OSError:
        pass


def run(cmd: list[str], log=print, cwd: Path | None = None) -> int:
    log(f"$ {' '.join(cmd)}")
    _file_log(f"$ {' '.join(cmd)}")
    proc = subprocess.Popen(
        cmd, cwd=cwd or ROOT, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, text=True,
    )
    assert proc.stdout is not None
    for line in proc.stdout:
        log(line.rstrip())
        _file_log(line.rstrip())
    proc.wait()
    return proc.returncode


def out(cmd: list[str]) -> str:
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    return r.stdout.strip()


# --- distro ------------------------------------------------------------

def distro() -> str:
    """Return 'nixos' or 'arch' from /etc/os-release."""
    try:
        text = Path("/etc/os-release").read_text()
    except OSError:
        return "arch"
    fields = {}
    for line in text.splitlines():
        if "=" in line:
            key, val = line.split("=", 1)
            fields[key.strip()] = val.strip().strip('"')
    if fields.get("ID") == "nixos" or "nixos" in fields.get("ID_LIKE", ""):
        return "nixos"
    return "arch"


def hosts() -> list[str]:
    d = ROOT / "nix" / "hosts"
    if not d.is_dir():
        return []
    return sorted(p.name for p in d.iterdir() if p.is_dir() and not p.name.startswith("."))


def rebuild(host: str, log=print) -> int:
    return run(["sudo", "nixos-rebuild", "switch", "--flake", f"{ROOT / 'nix'}#{host}"], log)



# --- git ---------------------------------------------------------------

def current_branch() -> str:
    return out(["git", "branch", "--show-current"])


def hooks_wired() -> bool:
    return out(["git", "config", "core.hooksPath"]) == "scripts/git-hooks"


def wire_hooks() -> None:
    subprocess.run(["git", "config", "core.hooksPath", "scripts/git-hooks"], cwd=ROOT)


def checkout(branch: str, log=print) -> int:
    return run(["git", "checkout", branch], log)


def pull(log=print) -> int:
    return run(["git", "pull", "--ff-only"], log)


def mark_theme_local(log=print) -> int:
    script = ROOT / "scripts" / "mark-theme-local.sh"
    if not script.exists():
        return 0
    return run(["bash", str(script)], log)


def theme_files() -> list[str]:
    """Single source: parse paths from scripts/mark-theme-local.sh.

    The shell script stays the source of truth so the post-checkout
    hook works with bash+git only (no python/venv needed).
    """
    script = ROOT / "scripts" / "mark-theme-local.sh"
    try:
        text = script.read_text()
    except OSError:
        return []
    paths = []
    for line in text.splitlines():
        line = line.strip().strip("\\").strip()
        if line.startswith('"') and "/" in line:
            paths.append(line.strip('"'))
    return paths


def skip_worktree_files() -> set[str]:
    files = set()
    for line in out(["git", "ls-files", "-v"]).splitlines():
        if line.startswith("S "):
            files.add(line[2:].strip())
        elif line.startswith("S"):
            files.add(line[1:].strip())
    return files


def skip_worktree_count() -> int:
    return len(skip_worktree_files())


# --- packages ----------------------------------------------------------

def have(bin_: str) -> bool:
    return bool(bin_) and shutil.which(bin_) is not None


def pkg_installed(pkg: str) -> bool:
    if distro() == "nixos":
        return False
    return subprocess.run(["pacman", "-Q", pkg], capture_output=True).returncode == 0


def batch_pkg_status(pkgs: list[str]) -> dict[str, bool]:
    """One pacman call for many packages -> {pkg: installed}."""
    return {p: bool(v) for p, v in batch_pkg_versions(pkgs).items()}


def batch_pkg_versions(pkgs: list[str]) -> dict[str, str]:
    """One pacman call for many packages -> {pkg: version or ''}."""
    pkgs = sorted({p for p in pkgs if p})
    versions = {p: "" for p in pkgs}
    if not pkgs or distro() == "nixos":
        return versions
    r = subprocess.run(["pacman", "-Q", *pkgs], capture_output=True, text=True)
    for line in r.stdout.splitlines():
        parts = line.split(" ", 1)
        if parts[0] in versions:
            versions[parts[0]] = parts[1] if len(parts) > 1 else "?"
    return versions


_PKG_INFO: dict[str, str] = {}


def batch_pkg_info(pkgs: list[str]) -> dict[str, str]:
    """One pacman -Si call for many packages -> {pkg: short description}.

    Repo packages only; AUR and offline machines fall back to '' (names shown).
    Results cached per process so repeated review screens stay instant.
    """
    pkgs = sorted({p for p in pkgs if p})
    missing = [p for p in pkgs if p not in _PKG_INFO]
    if missing and distro() != "nixos":
        r = subprocess.run(["pacman", "-Si", *missing], capture_output=True, text=True)
        name, desc = "", ""
        for line in r.stdout.splitlines() + [""]:
            if line.startswith("Name"):
                name = line.split(":", 1)[1].strip()
            elif line.startswith("Description"):
                desc = line.split(":", 1)[1].strip()
            elif not line.strip() and name:
                _PKG_INFO[name] = desc[:100]
                name, desc = "", ""
        for p in missing:
            _PKG_INFO.setdefault(p, "")
    return {p: _PKG_INFO.get(p, "") for p in pkgs}


def missing_pacman(apps: list[App]) -> list[str]:
    return [p for a in apps for p in a.pacman if not pkg_installed(p)]


def missing_aur(apps: list[App]) -> list[str]:
    return [p for a in apps for p in a.aur if not pkg_installed(p)]


def plan_install(apps: list[App], cats: set[str] | None = None) -> dict[str, list[str]]:
    """Missing-only plan for the summary screen (apps plus install-only cats)."""
    pac = set(missing_pacman(apps))
    aur = set(missing_aur(apps))
    missing = missing_cat_pkgs(cats or set())
    pac |= set(missing["pacman"])
    aur |= set(missing["aur"])
    return {
        "pacman": sorted(pac),
        "aur": sorted(aur),
        "stow": sorted({a.name for a in apps}),
    }


def cat_pkgs(names: set[str] | list[str]) -> dict[str, list[str]]:
    """Full member lists for install-only categories (preview). No install check."""
    from .apps import CAT_PKGS
    return {
        "pacman": sorted({p for n in names if n in CAT_PKGS for p in CAT_PKGS[n]["pacman"]}),
        "aur": sorted({p for n in names if n in CAT_PKGS for p in CAT_PKGS[n]["aur"]}),
    }


def missing_cat_pkgs(names: set[str] | list[str]) -> dict[str, list[str]]:
    """Install-only category members not yet installed (matches install behavior)."""
    full = cat_pkgs(names)
    return {
        "pacman": sorted(p for p in full["pacman"] if not pkg_installed(p)),
        "aur": sorted(p for p in full["aur"] if not pkg_installed(p)),
    }


def install_explicit(pac: list[str], aur: list[str], log=print, empty_msg: str = "Nothing to install.") -> int:
    """Shared sudo -> pacman -> yay tail."""
    if pac or aur:
        log("sudo: caching credentials (a password prompt may appear).")
        run(["sudo", "-v"], log)
    if pac:
        if run(["sudo", "pacman", "-S", "--needed", "--noconfirm", *pac], log):
            return 1
    if aur:
        if ensure_yay(log):
            return 1
        if run(["yay", "-S", "--needed", "--noconfirm", *aur], log):
            return 1
    if not pac and not aur:
        log(empty_msg)
    return 0


def install_packages(apps: list[App], cats: set[str] | None = None, log=print) -> int:
    if distro() == "nixos":
        log("NixOS: packages are declarative - edit nix/modules and run Rebuild system.")
        return 0
    pac = sorted(set(missing_pacman(apps)))
    aur = sorted(set(missing_aur(apps)))
    missing = missing_cat_pkgs(cats or set())
    pac += [p for p in missing["pacman"] if p not in pac]
    aur += [p for p in missing["aur"] if p not in aur]
    return install_explicit(sorted(pac), sorted(aur), log, "All selected packages already installed.")


def ensure_yay(log=print) -> int:
    if shutil.which("yay"):
        return 0
    log("yay missing, bootstrapping yay-bin...")
    if run(["sudo", "pacman", "-S", "--needed", "--noconfirm", "base-devel", "git"], log):
        return 1
    shutil.rmtree("/tmp/yay-bin", ignore_errors=True)
    if run(["git", "clone", "https://aur.archlinux.org/yay-bin.git", "/tmp/yay-bin"], log):
        return 1
    return run(["makepkg", "-si", "--noconfirm"], log, cwd=Path("/tmp/yay-bin"))


# --- stow --------------------------------------------------------------

def no_share_file(app: App) -> Path | None:
    """Return the .no-share marker gating an app (category or app level)."""
    for scope in (ROOT / "apps" / app.cat, ROOT / "apps" / app.cat / app.name):
        if (scope / ".no-share").exists():
            return scope / ".no-share"
    return None


def _backup_conflicts(pkg_dir: Path, log=print, extra_skip: tuple[str, ...] = ()) -> None:
    for child in sorted(pkg_dir.iterdir()):
        if child.name in (".no-share", ".do-not-stow.md") or child.name.startswith(".git"):
            continue
        if child.name in extra_skip:
            continue
        target = HOME / child.name
        if target.exists() and not target.is_symlink():
            shutil.move(str(target), str(target) + ".bak")
            log(f"Backed up {target} to {target}.bak")


def stow_app(app: App, log=print, force: bool = False) -> int:
    pkg = ROOT / "apps" / app.cat / app.name
    if not pkg.is_dir():
        log(f"{app.name}: {pkg} not found, skipped.")
        return 1
    marker = no_share_file(app)
    if marker and not force:
        warn = marker.parent / ".do-not-stow.md"
        if warn.exists():
            log(warn.read_text())
        log(f"{app.name}: marked .no-share at {marker.parent.name}/ - skipped.")
        return 0
    _backup_conflicts(pkg, log)
    eff = "\\.do-not-stow\\.md"
    if app.ignore:
        eff = f"({app.ignore}|{eff})"
    log(f"stow {app.name}")
    return run(
        ["stow", "-d", str(ROOT / "apps" / app.cat), "-t", str(HOME),
         f"--ignore={eff}", app.name], log
    )


def stow_top(pkg_name: str, log=print, force: bool = False) -> int:
    src = ROOT / pkg_name
    if (src / ".no-share").exists() and not force:
        warn = src / ".do-not-stow.md"
        if warn.exists():
            log(warn.read_text())
        log(f"{pkg_name}: marked .no-share - skipped (confirm to override).")
        return 0
    _backup_conflicts(src, log)
    log(f"stow {pkg_name}")
    return run(
        ["stow", "-d", str(ROOT), "-t", str(HOME), "--ignore=\\.do-not-stow\\.md", pkg_name], log
    )


def stow_category_pkg(cat: str, log=print) -> int:
    """Stow a whole category dir from apps/ (tty)."""
    return run(["stow", "-d", str(ROOT / "apps"), "-t", str(HOME), cat], log)


def apply_cat(cat: str, log=print, noctalia: str | None = None, force: bool = False) -> None:
    """Apply a whole-category selection (tty, gtk, qt, noctalia, install-only cats)."""
    from .apps import INSTALL_CATS
    if cat in INSTALL_CATS:
        log(f"{cat}: packages only, handled in package step.")
        return
    if cat == "tty":
        log(f"stow {cat}")
        stow_category_pkg(cat, log)
    elif cat == "gtk":
        log("NOTE: gtk is .no-share; running mac-tahoe reload.sh")
        run_script("gtk/mac-tahoe/reload.sh", log)
    elif cat == "qt":
        stow_top("qt", log, force=force)
    elif cat == "noctalia":
        if noctalia:
            stow_top(f"noctalia-{noctalia}", log, force=force)
        else:
            log("noctalia: no machine given, skipped. "
                "stow -d ~/dotfiles-pub -t ~ noctalia-dell (or -hp) manually.")


def run_script(rel: str, log=print) -> int:
    script = ROOT / rel
    if not script.exists():
        log(f"{rel} not found, skipped.")
        return 1
    return run(["bash", str(script)], log)


# --- state -------------------------------------------------------------

def record_installed(apps: list[App], cats: set[str] | None = None) -> None:
    """Remember what was applied so Update can redo it.

    Lines are 'cat|name' for apps and '@cat' for whole categories.
    """
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    lines = {f"{a.cat}|{a.name}" for a in apps} | {f"@{c}" for c in (cats or set())}
    existing = set(STATE_FILE.read_text().splitlines()) if STATE_FILE.exists() else set()
    STATE_FILE.write_text("\n".join(sorted(existing | lines)) + "\n")


def recorded_lines() -> list[str]:
    return STATE_FILE.read_text().splitlines() if STATE_FILE.exists() else []


def recorded_apps() -> list[App]:
    by_key = {(a.cat, a.name): a for a in APPS}
    out_: list[App] = []
    for line in recorded_lines():
        if "|" in line:
            cat, name = line.split("|", 1)
            if (cat, name) in by_key:
                out_.append(by_key[(cat, name)])
    return out_


def recorded_cats() -> list[str]:
    cats = [
        l[1:] for l in recorded_lines()
        if l.startswith("@") and not l.startswith("@rebuild:") and not l.startswith("@profile:")
    ]
    # legacy compat: old '@profile:name' lines replay as categories (same names)
    cats += [l.split(":", 1)[1] for l in recorded_lines() if l.startswith("@profile:")]
    return cats


def record_rebuild(host: str) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    line = f"@rebuild:{host}"
    existing = set(STATE_FILE.read_text().splitlines()) if STATE_FILE.exists() else set()
    STATE_FILE.write_text("\n".join(sorted(existing | {line})) + "\n")


def recorded_hosts() -> list[str]:
    return [l.split(":", 1)[1] for l in recorded_lines() if l.startswith("@rebuild:")]


# --- validation --------------------------------------------------------

def validate() -> list[tuple[str, str, str]]:
    """Return (level, item, detail); level in PASS/WARNING/ERROR."""
    checks: list[tuple[str, str, str]] = []

    branch = current_branch()
    if branch in ("master", "dynamic"):
        checks.append(("PASS", "branch", branch))
    elif branch:
        checks.append(("WARNING", "branch", f"on '{branch}', not master/dynamic"))
    else:
        checks.append(("ERROR", "branch", "detached HEAD or not a repo"))

    if hooks_wired():
        checks.append(("PASS", "git hooks", "core.hooksPath -> scripts/git-hooks"))
    else:
        checks.append(("ERROR", "git hooks", "core.hooksPath not set; run any installer op"))

    hook = ROOT / "scripts" / "git-hooks" / "post-checkout"
    if hook.exists() and os.access(hook, os.X_OK):
        checks.append(("PASS", "post-checkout hook", "present + executable"))
    else:
        checks.append(("ERROR", "post-checkout hook", "missing or not executable"))

    if distro() == "nixos":
        for tool, level in (("nix", "ERROR"), ("nixos-rebuild", "ERROR"), ("git", "ERROR")):
            if shutil.which(tool):
                checks.append(("PASS", tool, "found"))
            else:
                checks.append((level, tool, "missing"))
        flake = ROOT / "nix" / "flake.nix"
        if flake.exists():
            checks.append(("PASS", "flake.nix", str(flake)))
        else:
            checks.append(("ERROR", "flake.nix", "missing"))
        host_list = hosts()
        if host_list:
            checks.append(("PASS", "nix hosts", ", ".join(host_list)))
        else:
            checks.append(("WARNING", "nix hosts", "none under nix/hosts"))
    else:
        for tool, level in (("stow", "ERROR"), ("git", "ERROR"), ("pacman", "ERROR"), ("yay", "WARNING")):
            if shutil.which(tool):
                checks.append(("PASS", tool, "found"))
            else:
                checks.append((level, tool, "missing"))

    if branch == "dynamic":
        expected = set(theme_files())
        marked = skip_worktree_files()
        missing = sorted(expected - marked)
        if not expected:
            checks.append(("WARNING", "skip-worktree themes", "no paths in mark-theme-local.sh"))
        elif not missing:
            checks.append(("PASS", "skip-worktree themes", f"{len(marked & expected)}/{len(expected)} files marked"))
        else:
            show = ", ".join(missing[:3]) + (f" +{len(missing) - 3} more" if len(missing) > 3 else "")
            checks.append(("WARNING", "skip-worktree themes", f"{len(missing)} unmarked: {show}"))
            for m in missing[:5]:
                if not (ROOT / m).exists():
                    checks.append(("ERROR", "theme file missing", f"{m} listed but not on disk"))

    for app in recorded_apps():
        if app.bin:
            if have(app.bin):
                checks.append(("PASS", f"{app.name} binary", app.bin))
            else:
                checks.append(("WARNING", f"{app.name} binary", f"{app.bin} missing"))
        pkg = ROOT / "apps" / app.cat / app.name
        if not pkg.is_dir():
            checks.append(("ERROR", f"{app.name} files", f"{pkg} missing"))
            continue
        for child in sorted(pkg.iterdir()):
            if child.name in (".no-share", ".do-not-stow.md") or child.name.startswith(".git"):
                continue
            target = HOME / child.name
            if target.is_symlink():
                if target.exists():
                    checks.append(("PASS", f"{app.name} -> {child.name}", "symlink ok"))
                else:
                    checks.append(("ERROR", f"{app.name} -> {child.name}", "broken symlink"))
            elif target.exists():
                checks.append(("WARNING", f"{app.name} -> {child.name}", "exists, not a symlink"))
            else:
                checks.append(("WARNING", f"{app.name} -> {child.name}", "not linked"))
    if not recorded_apps():
        checks.append(("WARNING", "installed apps", "no record yet; apply dotfiles first"))
    return checks

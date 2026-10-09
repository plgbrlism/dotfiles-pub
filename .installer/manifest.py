"""parse the manifest tables"""
from dataclasses import dataclass

from . import paths

n_cols = 6
skip_names = {".no-share", ".do-not-stow.md", "SHARE-WARNING.md", "__pycache__"}


@dataclass
class app:
    cat: str
    name: str
    pacman: list[str]
    aur: list[str]
    bin: str
    ignore: str
    dir: str          # apps/<cat>, stow parent
    pkg: str          # src path
    stowable: bool    # false for rows naming a top-level setup dir


def words(s: str) -> list[str]:
    return s.split()


def rows(path, n: int = n_cols) -> list[list[str]]:
    """pipe table -> padded row lists, comments and blanks dropped"""
    out = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        cols = line.split("|")
        cols += [""] * (n - len(cols))
        out.append(cols[:n])
    return out


def apps() -> list[app]:
    """every manifest row. gtk and qt name top-level setup dirs, stowable False."""
    out = []
    for cat, name, pac, aur, bin_, ign in rows(paths.manifests / "apps.txt"):
        pkg = paths.root / "apps" / cat / name
        setup_dir = paths.root / cat
        out.append(app(cat, name, words(pac), words(aur), bin_, ign.strip(),
                       paths.root / "apps" / cat, pkg,
                       pkg.is_dir() or not setup_dir.is_dir()))
    return out


def setup_dirs() -> list[str]:
    """top-level dirs with a setup script and .no-share: gtk and qt"""
    out = []
    for d in sorted(paths.root.iterdir()):
        if not d.is_dir() or not (d / ".no-share").exists():
            continue
        if (d / f"setup-{d.name}.sh").exists():
            out.append(d.name)
    return out


def groups() -> list[tuple[str, list[str], list[str]]]:
    return [(g, words(pac), words(aur))
            for g, pac, aur in rows(paths.manifests / "groups.txt", 3)]


def group_names() -> list[str]:
    return [g for g, _, _ in groups()]


def by_key() -> dict[str, app]:
    """label -> app, the pick key used by state and the basket"""
    return {f"{a.cat}/{a.name}": a for a in apps()}


def app_cats() -> list[str]:
    seen: dict[str, None] = {}
    for a in apps():
        seen.setdefault(a.cat, None)
    return list(seen)


def whole_cats() -> list[app]:
    """@dir rows stow an entire apps/<cat> in one unit"""
    return [a for a in apps() if a.name.startswith("@")]


def top_stow() -> list[app]:
    """dirs stowed from repo root: noctalia variants, anything else .no-share"""
    out = []
    for d in sorted(paths.root.iterdir()):
        if not d.is_dir() or d.name.startswith("."):
            continue
        if d.name == "apps" or not (d / ".config").is_dir():
            continue
        out.append(app("", d.name, [], [], "", "", paths.root, d, True))
    return out


def has_no_share(p: paths.Path) -> bool:
    return (p / ".no-share").exists()


def no_share_scope(a: app) -> str | None:
    """nearest .no-share marker gating this app, or None"""
    for scope in (a.dir, a.pkg):
        if has_no_share(scope):
            return scope.name
    return None
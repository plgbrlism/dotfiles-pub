"""selection screens and the ordered steps"""
from . import check, manifest, paths, pkg, preflight, repo, state, stow, theme, ui

setup_cats = ["gtk", "qt"]


def setup_dirs() -> list[str]:
    """setup dirs present in this repo, falls back to gtk and qt"""
    found = manifest.setup_dirs()
    return found or setup_cats


def label(a) -> str:
    """basket label and pick key for an app"""
    return f"{a.cat}/{a.name}"


def pick_apps() -> tuple[list, list[str]]:
    """arrow-key basket over stowable apps, returns (apps, install-only groups)"""
    apps = [a for a in manifest.apps() if a.stowable]
    picks = ui.multi("apps to apply", [label(a) for a in apps]) or []
    groups = ui.multi("install-only groups", manifest.group_names()) or []
    keys = manifest.by_key()
    return [keys[p] for p in picks if p in keys], groups


def review(apps: list, groups: list[str]) -> bool:
    plan = pkg.plan([p for a in apps for p in a.pacman], [p for a in apps for p in a.aur])
    rows = []
    if plan["pacman"]:
        rows.append(("pacman", ", ".join(plan["pacman"])))
    if plan["aur"]:
        rows.append(("aur", ", ".join(plan["aur"])))
    if groups:
        rows.append(("groups", ", ".join(groups)))
    if manifest.setup_dirs():
        rows.append(("setup", " ".join(manifest.setup_dirs())))
    rows.append(("stow", f"{len(apps)} app(s)"))
    ui.head("review")
    ui.console.print(ui.table([("what", {"style": "bold"}), ("detail", {})], rows))
    ui.say()
    return ui.confirm("apply?", default=True)


def step_pkgs(apps: list, groups: list[str]) -> int:
    if pkg.is_nixos():
        ui.warn("nixos: packages are declarative, edit nix/modules and rebuild")
        return 0
    plan = pkg.plan([p for a in apps for p in a.pacman], [p for a in apps for p in a.aur])
    if groups:
        gp = pkg.missing([p for g, pac, _ in manifest.groups() if g in groups for p in pac])
        ga = pkg.missing([p for g, _, aur in manifest.groups() if g in groups for p in aur])
        plan["pacman"] = sorted(set(plan["pacman"]) | set(gp))
        plan["aur"] = sorted(set(plan["aur"]) | set(ga))
    ui.head("packages")
    return pkg.install(plan["pacman"], plan["aur"], "all selected already installed")


def step_stow(apps: list, force: bool = False) -> int:
    """stow the picked apps. top dirs stay gated by their .no-share, only an
    explicit force touches them."""
    ui.head("stow")
    keys = {label(a) for a in apps}
    rc = 0
    for kind, a in stow.all_pkgs():
        if kind != "pkg":
            if not force:
                continue
        elif label(a) not in keys:
            continue
        rc |= stow.apply(kind, a, force)
    return rc


def step_stow_cli() -> int:
    apps, _ = _last_pick()
    if not apps:
        ui.warn("nothing recorded yet, run full install first")
        return 1
    return step_stow(apps)


def step_hooks() -> int:
    ui.head("hooks")
    return theme.install_hooks()


def step_themes(names: list[str] | None = None) -> int:
    return theme.setup(names or setup_dirs())


def step_bits() -> int:
    ui.head("theme bits")
    theme.apply_bits(repo.branch())
    ui.ok(f"{theme.skip_count()} skip-worktree")
    return 0


def step_validate() -> int:
    ui.head("validate")
    return 0 if check.report(check.run()) else 1


def step_update() -> int:
    ui.head("update")
    if repo.pull():
        return 1
    apps, groups = state.reads()
    if not apps:
        ui.warn("nothing recorded yet, run full install first")
        return 1
    known = manifest.by_key()
    chosen = [known[k] for k in apps if k in known]
    step_pkgs(chosen, groups)
    step_stow(chosen)
    step_hooks()
    step_themes()
    step_bits()
    return step_validate()


def step_rebuild() -> int:
    ui.head("rebuild nixos")
    hs = repo.hosts()
    if not hs:
        ui.warn("no nix/hosts found")
        return 1
    host = ui.pick("host", hs)
    return repo.rebuild(host) if host else 0


def full() -> int:
    """preflight, pick, review, then every step in order"""
    ui.title("dotfiles installer", str(paths.root))
    ui.say()
    if not preflight.run():
        ui.say()
        ui.bad("preflight failed")
        return 1
    ui.say()
    apps, groups = pick_apps()
    ui.say()
    if not apps and not groups:
        ui.warn("nothing picked")
        return 0
    if not review(apps, groups):
        ui.warn("cancelled")
        return 0
    rc = step_pkgs(apps, groups)
    rc |= step_stow(apps)
    rc |= step_hooks()
    rc |= step_themes()
    rc |= step_bits()
    rc |= step_validate()
    state.record([label(a) for a in apps], groups)
    ui.say()
    ui.ok(f"done, picks at {state.picks_file}")
    return rc


def _last_pick() -> tuple[list, list[str]]:
    """recorded picks resolved against the current manifest"""
    keys = manifest.by_key()
    picked, groups = state.reads()
    return [keys[k] for k in picked if k in keys], groups


def step_pkgs_cli() -> int:
    apps, groups = _last_pick()
    if not apps and not groups:
        ui.warn("nothing recorded yet, run full install first")
        return 1
    return step_pkgs(apps, groups)


steps = {
    "full": full,
    "packages": step_pkgs_cli,
    "stow": step_stow_cli,
    "hooks": step_hooks,
    "themes": step_themes,
    "theme-bits": step_bits,
    "validate": step_validate,
    "update": step_update,
    "rebuild": step_rebuild,
}


menu = [
    ("full", "full install", "preflight, packages, stow, hooks, themes, validate"),
    ("packages", "packages", "install missing packages from the manifests"),
    ("stow", "stow", "link configs into home, installs nothing"),
    ("hooks", "hooks", "wire core.hooksPath"),
    ("themes", "themes", "run gtk and qt setup"),
    ("theme-bits", "theme bits", "reapply skip-worktree bits"),
    ("validate", "validate", "check packages, links, hooks, binaries"),
    ("update", "update", "pull, replay the last full install"),
    ("rebuild", "rebuild nixos", "nixos-rebuild switch"),
    ("quit", "quit", ""),
]


def cli(argv: list[str]) -> int:
    if argv:
        fn = steps.get(argv[0])
        if not fn:
            ui.bad(f"unknown step: {argv[0]}")
            return 2
        return fn()
    if not _tty():
        ui.bad("no tty, run without args for the menu")
        return 2
    while True:
        ui.title("dotfiles installer", str(paths.root))
        rows = [(f"[key]{i + 1}[/]", name, desc) for i, (_, name, desc) in enumerate(menu)]
        ui.console.print(ui.table([("", {}), ("action", {"style": "bold"}), ("", {})], rows))
        ui.say()
        # no prefilled value, it would swallow the first keypress
        answer = ui.ask("number")
        if answer is None:
            ui.say()
            ui.ok("cancelled")
            return 0
        choice = answer.strip() or "1"
        ui.say()
        if choice.isdigit() and 1 <= int(choice) <= len(menu):
            key = menu[int(choice) - 1][0]
        else:
            key = choice if choice in steps or choice == "quit" else ""
        if not key:
            ui.warn("not on the list, quitting")
            return 0
        if key == "quit":
            ui.ok("bye")
            return 0
        try:
            steps[key]()
            ui.say()
            if not ui.pause():
                ui.say()
                ui.ok("cancelled")
                return 0
            ui.console.clear()
        except KeyboardInterrupt:
            ui.say()
            ui.ok("cancelled")
            return 0


def _tty() -> bool:
    import sys
    return sys.stdin.isatty() and sys.stdout.isatty()
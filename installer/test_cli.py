"""Smoke test for the fzf CLI.

The single fzf subprocess seam (fzfui._run) is replaced with a scripted
queue, and ops side effects are stubbed, so nothing real is touched.
Run:  python3 installer/test_cli.py
"""
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from installer import cli, fzfui, ops  # noqa: E402


class FakeFzf:
    """Answers are chosen values (or None to cancel); echoed as fzf would."""

    def __init__(self, answers):
        self.answers = list(answers)
        self.runs = []

    def __call__(self, argv, input_text):
        self.runs.append((argv, input_text))
        ans = self.answers.pop(0) if self.answers else None
        if ans is None:
            return (130, "")
        for line in input_text.splitlines():
            if line.split("\t", 1)[0] == ans:
                return (0, line + "\n")
        raise AssertionError(f"no line for {ans!r} in {input_text!r}")

    def header(self, i):
        argv = self.runs[i][0]
        return argv[argv.index("--header") + 1]


def _setup(answers, calls=None, **kw):
    fake = FakeFzf(answers)
    fzfui._run = fake
    said = []
    fzfui.say = lambda text="", color=None: said.append(text)
    _patch_ops(calls if calls is not None else [], **kw)
    return fake, said


def _patch_ops(monkeypatch_calls, branch="dynamic", no_share=True):
    def pkg(*a, **k):
        apps = [x.name for x in a[0]] if a else []
        cats = sorted(a[1]) if len(a) > 1 and not callable(a[1]) else None
        monkeypatch_calls.append(("install_packages", apps, cats))
        return 0

    def stow(app, log=print, force=False):
        monkeypatch_calls.append(("stow_app", app.name, force))
        return 0

    def apply_cat(cat, log=print, noctalia=None, force=False):
        monkeypatch_calls.append(("apply_cat", cat, noctalia, force))

    def rec(apps, cats=None):
        monkeypatch_calls.append(("record_installed", [a.name for a in apps], cats))

    ops.batch_pkg_status = lambda pkgs: {p: False for p in pkgs}
    ops.batch_pkg_versions = lambda pkgs: {p: "1.0-test" for p in pkgs}
    ops.batch_pkg_info = lambda pkgs: {p: f"{p} desc" for p in pkgs}
    ops.cat_pkgs = lambda cats: {"pacman": ["x"], "aur": []}
    ops.missing_cat_pkgs = lambda names: {"pacman": [], "aur": []}
    ops.install_explicit = lambda pac, aur, log=print, empty_msg="": monkeypatch_calls.append(("install_explicit", list(pac), list(aur))) or 0
    ops.have = lambda b: False
    ops.plan_install = lambda apps, cats=None: {"pacman": [], "aur": [], "stow": []}
    ops.install_packages = pkg
    ops.stow_app = stow
    ops.apply_cat = apply_cat
    ops.record_installed = rec
    ops.wire_hooks = lambda: monkeypatch_calls.append(("wire_hooks",))
    ops.mark_theme_local = lambda log=print: monkeypatch_calls.append(("mark_theme_local",))
    ops.current_branch = lambda: branch
    ops.no_share_file = lambda app: Path("/x/.no-share") if no_share else None


def test_basket_toggle():
    _setup(["a", "a", "b", fzfui.DONE], branch="master")
    out = cli.basket_pick("Pick:", [("a", "A"), ("b", "B")])
    assert out == ["b"], out
    print("basket/toggle OK")


def test_basket_done_empty_and_esc():
    fake, _ = _setup([fzfui.DONE, "a", fzfui.DONE], branch="master")
    out = cli.basket_pick("Pick:", [("a", "A")])
    assert out == ["a"], out
    assert "nothing picked yet" in fake.header(1), fake.runs
    fake, _ = _setup([None])
    assert cli.basket_pick("Pick:", [("a", "A")]) is None
    print("basket/empty OK")


def test_stow_dynamic():
    calls = []
    _setup(["cli|starship", fzfui.DONE, "execute", "no"], calls, branch="dynamic", no_share=True)
    cli.run_pick("stow")
    assert ("wire_hooks",) in calls, calls
    assert ("stow_app", "starship", False) in calls, calls
    assert ("record_installed", ["starship"], set()) in calls, calls
    assert not any(c[0] == "install_packages" for c in calls), calls
    assert ("mark_theme_local",) in calls, calls
    print("stow/dynamic OK")


def test_full_cat_install():
    calls = []
    _setup(["cli|starship", "media", fzfui.DONE, "mpv", fzfui.DONE, "execute", "no"],
           calls, branch="dynamic", no_share=True)
    ops.plan_install = lambda apps, cats=None: {"pacman": ["mpv", "vlc"], "aur": [], "stow": []}
    cli.run_pick("install+stow")
    assert ("install_packages", ["starship"], None) in calls, calls
    assert ("install_explicit", ["vlc"], []) in calls, calls
    assert ("apply_cat", "media", None, False) in calls, calls
    assert ("record_installed", ["starship"], {"media"}) in calls, calls
    assert ("mark_theme_local",) in calls, calls
    print("full/cat OK")


def test_full_review_remove_and_back():
    calls = []
    _, said = _setup(["cli|starship", "media", fzfui.DONE, "mpv", fzfui.DONE, "execute"],
                     calls, branch="dynamic", no_share=False)
    ops.plan_install = lambda apps, cats=None: {"pacman": ["mpv", "vlc"], "aur": [], "stow": []}
    cli.run_pick("install+stow")
    assert ("install_explicit", ["vlc"], []) in calls, calls
    assert "Step 2 of 3" in "\n".join(said), said
    calls2 = []
    _setup(["cli|starship", fzfui.DONE, fzfui.DONE, "back", None],
           calls2, branch="dynamic", no_share=False)
    ops.plan_install = lambda apps, cats=None: {"pacman": ["mpv"], "aur": [], "stow": []}
    cli.run_pick("install+stow")
    assert not any(c[0] == "install_explicit" for c in calls2), calls2
    assert not any(c[0] == "record_installed" for c in calls2), calls2
    print("full/review OK")


def test_packages_no_stow():
    calls = []
    _setup(["cli|starship", "media", fzfui.DONE, fzfui.DONE, "execute"], calls, branch="master")
    ops.plan_install = lambda apps, cats=None: {"pacman": ["mpv"], "aur": ["vv-bin"], "stow": []}
    cli.run_pick("packages")
    assert ("install_packages", ["starship"], None) in calls, calls
    assert ("install_explicit", ["mpv"], ["vv-bin"]) in calls, calls
    assert not any(c[0] == "stow_app" for c in calls), calls
    assert not any(c[0] == "record_installed" for c in calls), calls
    assert not any(c[0] == "mark_theme_local" for c in calls), calls
    print("packages OK")


def test_cancel_pick():
    calls = []
    _setup([None], calls)
    cli.run_pick("stow")
    assert calls == [], calls
    print("cancel OK")


def test_branch_switch():
    calls = []
    fake, _ = _setup(["dynamic"], calls, branch="master")
    ops.checkout = lambda b, log=print: (calls.append(("checkout", b)) or 0)
    cli.switch_branch()
    assert ("checkout", "dynamic") in calls, calls
    assert ("wire_hooks",) in calls, calls
    assert ("mark_theme_local",) in calls, calls
    assert fake.runs[0][1].splitlines()[0].startswith("master"), fake.runs[0]
    print("branch OK")


def test_validate_runs():
    calls = []
    _, said = _setup([], calls)
    ops.validate = lambda: [("PASS", "branch", "dynamic"), ("ERROR", "stow", "missing")]
    cli.validate()
    assert said, "validate printed nothing"
    print("validate OK")


def test_cat_all_present_proof():
    _, said = _setup(["media", fzfui.DONE, "execute"], branch="master")
    cli.run_pick("packages")
    assert any("1.0-test" in p for p in said), said
    print("proof OK")


def test_update_replays_cats():
    calls = []
    _setup(["yes"], calls, branch="master")
    ops.pull = lambda log=print: calls.append(("pull",)) or 0
    ops.recorded_apps = lambda: []
    ops.recorded_cats = lambda: ["media"]
    cli.update()
    assert ("apply_cat", "media", None, True) in calls, calls
    assert any(c[0] == "install_packages" for c in calls), calls
    print("update/cats OK")


def test_legacy_profile_state():
    import importlib
    fresh = importlib.reload(ops)
    with tempfile.TemporaryDirectory() as tmp:
        state = Path(tmp) / "installed.txt"
        state.write_text("cli|starship\n@profile:tools\n@tty\n")
        fresh.recorded_lines = lambda: state.read_text().splitlines()
        assert "tools" in fresh.recorded_cats(), fresh.recorded_cats()
        assert "tty" in fresh.recorded_cats(), fresh.recorded_cats()
    print("legacy OK")


def test_menus():
    arch = {v for v, _ in cli.ARCH_MENU}
    nix = {v for v, _ in cli.NIXOS_MENU}
    assert {"full", "pkgs", "stow"} <= arch, arch
    assert "profiles" not in arch, arch
    assert "rebuild" in nix, nix
    assert not ({"full", "pkgs", "stow"} & nix), nix
    assert set(cli.ARCH_ACTIONS) == arch - {"exit"}, (cli.ARCH_ACTIONS.keys(), arch)
    for menu in (cli.ARCH_MENU, cli.NIXOS_MENU):
        for value, title in menu:
            assert ": " in title, (value, title)
    print("menus OK")


def test_fzf_args_and_parse():
    fake, _ = _setup(["a"])
    assert fzfui.pick("T:", [("a", "A"), ("b", "B")]) == "a"
    argv, text = fake.runs[0]
    assert text == "a\tA\nb\tB", repr(text)
    assert "--no-sort" in argv and argv[argv.index("--with-nth") + 1] == "2.."
    assert argv[argv.index("--delimiter") + 1] == "\t"
    assert any("pointer:#ff9d00" in a for a in argv), argv
    fake, _ = _setup(["a"])
    fzfui.pick("T:", [("a", "A")], preview="pacman -Si {1}")
    assert "--preview" in fake.runs[0][0], fake.runs[0]
    print("fzf-args OK")


def test_confirm_and_cancel():
    fake, _ = _setup(["no"])
    assert fzfui.confirm("Q?", default=False) is False
    assert fake.runs[0][1].splitlines()[0].startswith("no"), fake.runs[0]
    fake, _ = _setup(["yes"])
    assert fzfui.confirm("Q?", default=True) is True
    assert fake.runs[0][1].splitlines()[0].startswith("yes"), fake.runs[0]
    _setup([None])
    assert fzfui.pick("T:", [("a", "A")]) is None
    print("confirm OK")


def test_decide_order_and_guide():
    calls = []
    fake, said = _setup(["cli|starship", fzfui.DONE, "execute"], calls,
                        branch="dynamic", no_share=False)
    cli.run_pick("stow")
    joined = "\n".join(said)
    headers = "\n".join(a[a.index("--header") + 1] for a, _ in fake.runs)
    assert "Step 1 of 2" in headers, headers
    assert "Step 2 of 2" in joined, joined
    decide = [t for a, t in fake.runs if "Decide:" in a]
    assert decide, fake.runs
    first = decide[0].splitlines()[0]
    assert first.startswith("back"), decide
    print("guide OK")


def test_nixos_update_no_stow():
    calls = []
    _setup(["yes", "hp"], calls, branch="dynamic")
    ops.pull = lambda log=print: calls.append(("pull",)) or 0
    ops.hosts = lambda: ["hp"]
    ops.rebuild = lambda host, log=print: calls.append(("rebuild", host)) or 0
    ops.record_rebuild = lambda host: calls.append(("record_rebuild", host))
    cli.update_nixos()
    assert ("pull",) in calls, calls
    assert ("rebuild", "hp") in calls, calls
    assert ("record_rebuild", "hp") in calls, calls
    assert not any(c[0] == "stow_app" for c in calls), calls
    print("nixos update OK")


def test_no_questionary():
    root = Path(__file__).resolve().parent
    hits = [p.name for p in root.glob("*.py") if p.name != Path(__file__).name
            and ("import questionary" in p.read_text() or "from questionary" in p.read_text())]
    assert not hits, hits
    print("no-questionary OK")


def test_no_emdash():
    root = Path(__file__).resolve().parent.parent
    targets = [root / "README.md", root / "nix" / "paul-nix.md"]
    targets += sorted((root / "installer").glob("*.py"))
    dash = chr(8212)
    bad = [str(p) for p in targets if p.exists() and dash in p.read_text()]
    assert not bad, bad
    print("emdash OK")


if __name__ == "__main__":
    test_basket_toggle()
    test_basket_done_empty_and_esc()
    test_stow_dynamic()
    test_full_cat_install()
    test_full_review_remove_and_back()
    test_packages_no_stow()
    test_cancel_pick()
    test_branch_switch()
    test_validate_runs()
    test_cat_all_present_proof()
    test_update_replays_cats()
    test_legacy_profile_state()
    test_menus()
    test_fzf_args_and_parse()
    test_confirm_and_cancel()
    test_decide_order_and_guide()
    test_nixos_update_no_stow()
    test_no_questionary()
    test_no_emdash()
    print("OK")

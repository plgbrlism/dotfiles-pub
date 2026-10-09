"""applied picks, replayed by packages, stow, and update"""
from . import paths

picks_file = paths.state / "picks.txt"


def record(apps: list[str], cats: list[str]) -> None:
    """remember what a full install applied, so update can replay it"""
    paths.state.mkdir(parents=True, exist_ok=True)
    lines = set(apps) | {f"@{c}" for c in cats}
    old = set(picks_file.read_text().splitlines()) if picks_file.exists() else set()
    picks_file.write_text("\n".join(sorted(old | lines)) + "\n")


def reads() -> tuple[list[str], list[str]]:
    """recorded (apps, cats), empty when nothing was recorded yet"""
    if not picks_file.exists():
        return [], []
    apps, cats = [], []
    for line in picks_file.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        (cats.append(line[1:]) if line.startswith("@") else apps.append(line))
    return apps, cats
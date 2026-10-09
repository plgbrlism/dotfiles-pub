"""shared paths and state locations"""
import os
from pathlib import Path

root = Path(os.environ.get("PAUL_DOTFILES_ROOT", Path(__file__).resolve().parent.parent))
home = Path(os.environ.get("HOME", Path.home()))
state = home / ".local" / "state" / "dotfiles"
here = Path(__file__).resolve().parent
manifests = here / "manifests"

branch = "dynamic"
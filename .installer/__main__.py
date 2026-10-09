import sys

from . import menu

if __name__ == "__main__":
    sys.exit(menu.cli(sys.argv[1:]))
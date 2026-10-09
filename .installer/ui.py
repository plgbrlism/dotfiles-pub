"""menu rendering and prompts"""
import subprocess

import questionary
from prompt_toolkit import PromptSession
from prompt_toolkit.formatted_text import FormattedText
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.keys import Keys
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.theme import Theme
from rich import box

theme = Theme({
    "hdr": "bold cyan",
    "ok": "bold green",
    "warn": "bold yellow",
    "bad": "bold red",
    "dim": "grey54",
    "key": "bold magenta",
})
console = Console(theme=theme)
err = Console(stderr=True, theme=theme)

rule = "─" * 58


def say(msg: str = "") -> None:
    console.print(msg)


def dim(msg: str) -> None:
    console.print(f"[dim]{msg}[/]")


def title(text: str, sub: str = "") -> None:
    body = f"[hdr]{text}[/]"
    if sub:
        body += f"\n[dim]{sub}[/]"
    console.print(Panel(body, box=box.ROUNDED, border_style="cyan", padding=(0, 2)))


def rule_line() -> None:
    console.print(f"[dim]{rule}[/]")


def head(text: str) -> None:
    """section heading with breathing room above and below"""
    console.print()
    console.print(f"[key]{text}[/]")
    rule_line()


def ok(msg: str) -> None:
    console.print(f"[ok]ok[/]  {msg}")


def warn(msg: str) -> None:
    console.print(f"[warn]!![/]  {msg}")


def bad(msg: str) -> None:
    console.print(f"[bad]xx[/]  {msg}")


def note(msg: str) -> None:
    console.print(f"[dim]    {msg}[/]")


def table(cols: list[tuple], rows: list) -> Table:
    t = Table(box=box.SIMPLE_HEAD, pad_edge=False, header_style="hdr", border_style="dim")
    for col in cols:
        t.add_column(*col)
    for row in rows:
        t.add_row(*row)
    return t


def pick(msg: str, choices: list[str]) -> str | None:
    return questionary.select(msg, choices=choices, qmark="").ask()


def multi(msg: str, choices: list[str]) -> list[str]:
    return questionary.checkbox(msg, choices=choices, qmark="").ask() or []


def confirm(msg: str, default: bool = False) -> bool:
    return bool(questionary.confirm(msg, default=default, qmark="").ask())


def ask(msg: str, default: str = "") -> str | None:
    """None means the user hit ctrl-c, empty means they submitted the default"""
    return questionary.text(msg, default=default, qmark="").ask()


def pause() -> None:
    """any key continues, ctrl-c raises for the caller to catch.

    questionary.press_any_key_to_continue cannot do this, it binds Keys.Any to
    an exit that yields None for every keypress including ctrl-c.
    """
    bindings = KeyBindings()

    @bindings.add(Keys.Any)
    def _go(event):
        event.app.exit(result=True)

    session = PromptSession(
        lambda: FormattedText([("class:question", " Press any key to continue... ")]),
        key_bindings=bindings)
    session.app.run()


def stream(cmd: list[str], cwd=None, env=None) -> int:
    """run cmd, echo output live, return exit code"""
    dim("$ " + " ".join(cmd))
    try:
        proc = subprocess.run(cmd, cwd=cwd, env=env, text=True, capture_output=True)
    except FileNotFoundError:
        bad(f"{cmd[0]}: not found")
        return 127
    if proc.stdout:
        console.print(proc.stdout.rstrip(), markup=False, highlight=False)
    if proc.returncode and proc.stderr:
        console.print(proc.stderr.rstrip(), markup=False, highlight=False, style="bad")
    return proc.returncode
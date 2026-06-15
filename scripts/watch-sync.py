#!/usr/bin/env python3
"""Pretty live monitor for the kernel write-back queue.

Copying to slow / removable filesystems (USB sticks, NTFS, FAT32) finishes
"instantly" because the data lands in the page cache as *dirty* pages and is
flushed to the device asynchronously. `cp` and most file managers return as
soon as the copy hits RAM, so the real progress is invisible — the bytes
dribble out to the device for seconds or minutes afterwards.

This watches /proc/meminfo (Dirty + Writeback = bytes still owed to disk) and
/proc/vmstat (nr_written = pages actually flushed) to show how much is left,
how fast it is draining, and an ETA.
"""
from __future__ import annotations

import argparse
import os
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

from rich import box
from rich.console import Group
from rich.panel import Panel
from rich.table import Table
from rich.text import Text
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Container
from textual.events import Resize
from textual.widgets import Footer, Header, Static

MEMINFO = Path("/proc/meminfo")
VMSTAT = Path("/proc/vmstat")
PAGE_SIZE = os.sysconf("SC_PAGE_SIZE")

# Below this much pending data we treat the queue as drained / idle.
IDLE_BYTES = 2 * 1024 * 1024


@dataclass(frozen=True)
class Theme:
    base00: str
    base01: str
    base02: str
    base03: str
    base05: str
    base08: str
    base0A: str
    base0B: str
    base0C: str
    base0D: str

    @staticmethod
    def from_env() -> "Theme":
        def color(name: str, fallback: str) -> str:
            value = os.environ.get(f"WATCH_SYNC_{name}", fallback).strip()
            if not value.startswith("#"):
                value = f"#{value}"
            return value

        return Theme(
            base00=color("BASE00", "#1e1e2e"),
            base01=color("BASE01", "#181825"),
            base02=color("BASE02", "#313244"),
            base03=color("BASE03", "#45475a"),
            base05=color("BASE05", "#cdd6f4"),
            base08=color("BASE08", "#f38ba8"),
            base0A=color("BASE0A", "#f9e2af"),
            base0B=color("BASE0B", "#a6e3a1"),
            base0C=color("BASE0C", "#94e2d5"),
            base0D=color("BASE0D", "#89b4fa"),
        )


THEME = Theme.from_env()


@dataclass(frozen=True)
class Sample:
    dirty: int
    writeback: int
    written_pages: int
    when: float

    @property
    def pending(self) -> int:
        return self.dirty + self.writeback


@dataclass(frozen=True)
class Snapshot:
    dirty: int
    writeback: int
    pending: int
    peak: int
    throughput: float  # bytes/sec actually flushed to disk
    progress: float | None
    eta_seconds: float | None
    subtitle: str


class SyncError(RuntimeError):
    pass


def read_meminfo() -> dict[str, int]:
    values: dict[str, int] = {}
    try:
        text = MEMINFO.read_text()
    except OSError as exc:
        raise SyncError(f"cannot read {MEMINFO}: {exc}") from exc
    for line in text.splitlines():
        key, _, rest = line.partition(":")
        rest = rest.strip()
        if rest.endswith(" kB"):
            try:
                values[key] = int(rest[:-3].strip()) * 1024
            except ValueError:
                continue
    return values


def read_written_pages() -> int:
    try:
        text = VMSTAT.read_text()
    except OSError:
        return 0
    for line in text.splitlines():
        if line.startswith("nr_written "):
            try:
                return int(line.split()[1])
            except (IndexError, ValueError):
                return 0
    return 0


def take_sample() -> Sample:
    mem = read_meminfo()
    return Sample(
        dirty=mem.get("Dirty", 0),
        writeback=mem.get("Writeback", 0),
        written_pages=read_written_pages(),
        when=time.monotonic(),
    )


def format_bytes(value: float) -> str:
    units = ("B", "KiB", "MiB", "GiB", "TiB")
    amount = float(value)
    for unit in units:
        if amount < 1024.0 or unit == units[-1]:
            if unit == "B":
                return f"{int(amount)} {unit}"
            return f"{amount:.1f} {unit}"
        amount /= 1024.0
    return f"{amount:.1f} TiB"


def format_eta(seconds: float | None) -> str:
    if seconds is None:
        return "—"
    seconds = int(round(seconds))
    if seconds < 60:
        return f"~{seconds}s"
    minutes, secs = divmod(seconds, 60)
    if minutes < 60:
        return f"~{minutes}m {secs:02d}s"
    hours, minutes = divmod(minutes, 60)
    return f"~{hours}h {minutes:02d}m"


def bar_style(percent: float | None) -> str:
    if percent is None:
        return THEME.base0C
    if percent >= 85:
        return THEME.base0B
    if percent >= 40:
        return THEME.base0A
    return THEME.base08


def text_bar(percent: float, width: int, *, style: str | None = None) -> Text:
    percent = max(0.0, min(100.0, percent))
    width = max(1, width)
    filled = min(width, round((percent / 100.0) * width))
    text = Text()
    text.append("█" * filled, style=style or bar_style(percent))
    text.append("░" * (width - filled), style=THEME.base03)
    return text


def render_snapshot(snapshot: Snapshot, width: int, interval: float) -> Panel:
    compact = width < 70
    label_width = min(14, max(9, width // 5))
    bar_width = max(8, width - label_width - 26)

    idle = snapshot.pending <= IDLE_BYTES

    header = Table.grid(expand=True)
    header.add_column("label", width=label_width, style="dim", no_wrap=True)
    header.add_column("value", ratio=1, overflow="fold")

    # Big drain progress bar.
    if snapshot.progress is not None and not idle:
        pct = max(0.0, min(100.0, snapshot.progress * 100.0))
        flushed = max(0, snapshot.peak - snapshot.pending)
        bar = Text()
        bar.append_text(text_bar(pct, bar_width, style=THEME.base0D))
        bar.append(f" {pct:>3.0f}%", style=f"bold {THEME.base0D}")
        header.add_row("Flushed", bar)
        if not compact:
            detail = Text(
                f"{format_bytes(flushed)} of {format_bytes(snapshot.peak)} drained",
                style="dim",
            )
            header.add_row("", detail)
    else:
        status = Text("queue drained — disk is in sync", style=f"bold {THEME.base0B}")
        header.add_row("Status", status)

    header.add_row("", Text(""))

    pending_text = Text(format_bytes(snapshot.pending), style=f"bold {THEME.base0A}")
    header.add_row("Pending", pending_text)
    header.add_row("Dirty", Text(f"{format_bytes(snapshot.dirty)}", style=THEME.base05))
    header.add_row("Writeback", Text(f"{format_bytes(snapshot.writeback)}", style=THEME.base05))

    rate_text = Text()
    rate_text.append(f"{format_bytes(snapshot.throughput)}/s", style=f"bold {THEME.base0C}")
    header.add_row("Throughput", rate_text)

    eta_style = THEME.base0B if idle else THEME.base0A
    header.add_row("ETA", Text(format_eta(snapshot.eta_seconds), style=eta_style))

    body: list[object] = [header]

    if not compact:
        body.append(Text(""))
        tip = Text(
            "Dirty = buffered in RAM, not yet on disk · Writeback = being written now.",
            style="dim italic",
        )
        body.append(tip)

    return Panel(
        Group(*body),
        title=f"[bold {THEME.base0D}]watch-sync • disk write-back[/]",
        subtitle=f"[{THEME.base03}]{snapshot.subtitle} • refresh {interval:g}s[/]",
        border_style=THEME.base0B if idle else THEME.base0D,
        box=box.ROUNDED if width >= 40 else box.SIMPLE,
        padding=(0, 1) if compact else (1, 2),
    )


class SyncMonitor:
    """Turns raw samples into a Snapshot with smoothed throughput and progress."""

    def __init__(self) -> None:
        self.prev: Sample | None = None
        self.peak: int = 0
        self.throughput: float = 0.0

    def update(self, sample: Sample) -> Snapshot:
        # Throughput from pages actually written out (smoothed EMA).
        if self.prev is not None:
            dt = sample.when - self.prev.when
            if dt > 0:
                pages = max(0, sample.written_pages - self.prev.written_pages)
                instant = (pages * PAGE_SIZE) / dt
                alpha = 0.5
                self.throughput = (alpha * instant) + ((1.0 - alpha) * self.throughput)

        pending = sample.pending

        # Track the high-water mark of a drain session; reset once drained so
        # the next copy gets a fresh 0→100% bar.
        if pending <= IDLE_BYTES:
            self.peak = pending
        elif pending > self.peak:
            self.peak = pending

        progress: float | None = None
        if self.peak > IDLE_BYTES:
            progress = max(0.0, min(1.0, (self.peak - pending) / self.peak))

        eta: float | None = None
        if pending > IDLE_BYTES and self.throughput > 1024:
            eta = pending / self.throughput

        self.prev = sample
        return Snapshot(
            dirty=sample.dirty,
            writeback=sample.writeback,
            pending=pending,
            peak=self.peak,
            throughput=self.throughput,
            progress=progress,
            eta_seconds=eta,
            subtitle=time.strftime("%Y-%m-%d %H:%M:%S"),
        )


class Dashboard(Static):
    def __init__(self, interval: float) -> None:
        super().__init__()
        self.interval = interval
        self.snapshot: Snapshot | None = None
        self.error: str | None = None

    def set_snapshot(self, snapshot: Snapshot) -> None:
        self.snapshot = snapshot
        self.error = None
        self.refresh(layout=True)

    def set_error(self, error: str) -> None:
        self.error = error
        self.refresh(layout=True)

    def on_resize(self, _: Resize) -> None:
        self.refresh(layout=True)

    def render(self) -> Panel:
        width = max(20, self.size.width)
        if self.error is not None:
            return Panel(
                Text(self.error, style=f"bold {THEME.base08}"),
                title=f"[bold {THEME.base08}]watch-sync[/]",
                border_style=THEME.base08,
                box=box.ROUNDED if width >= 40 else box.SIMPLE,
            )
        if self.snapshot is None:
            return Panel(
                "Sampling write-back queue…",
                title=f"[bold {THEME.base0D}]watch-sync[/]",
                border_style=THEME.base0D,
            )
        return render_snapshot(self.snapshot, width, self.interval)


class WatchSyncApp(App[None]):
    CSS = f"""
    Screen {{
        background: {THEME.base00};
        color: {THEME.base05};
    }}

    Header, Footer {{
        background: {THEME.base01};
        color: {THEME.base05};
    }}

    #frame {{
        width: 100%;
        height: 100%;
        padding: 1 2;
        background: {THEME.base00};
    }}

    Dashboard {{
        width: 100%;
        height: 100%;
        color: {THEME.base05};
    }}
    """

    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("s", "sync", "Force sync"),
        Binding("ctrl+c", "quit", "Quit", show=False),
    ]

    def __init__(self, interval: float) -> None:
        super().__init__()
        self.interval = interval
        self.dashboard = Dashboard(interval)
        self.monitor = SyncMonitor()

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Container(id="frame"):
            yield self.dashboard
        yield Footer()

    def on_mount(self) -> None:
        self.title = "watch-sync"
        self.sub_title = "disk write-back queue"
        self.update_snapshot()
        self.set_interval(self.interval, self.update_snapshot)

    def update_snapshot(self) -> None:
        try:
            self.dashboard.set_snapshot(self.monitor.update(take_sample()))
        except SyncError as exc:
            self.dashboard.set_error(str(exc))

    def action_sync(self) -> None:
        # Best-effort flush of the page cache so the queue drains promptly.
        try:
            os.sync()
        except OSError:
            pass


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="watch-sync",
        description="Pretty live monitor for the kernel disk write-back queue.",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=float(os.environ.get("WATCH_SYNC_INTERVAL", "0.5")),
        help="Refresh interval in seconds (default: WATCH_SYNC_INTERVAL or 0.5)",
    )
    parser.add_argument("--once", action="store_true", help="Print one snapshot and exit")
    return parser.parse_args(argv)


def main(argv: Sequence[str] = sys.argv[1:]) -> int:
    args = parse_args(argv)
    if args.interval <= 0:
        from rich.console import Console

        Console(stderr=True).print("[red]--interval must be greater than zero[/]")
        return 2

    try:
        if args.once:
            from rich.console import Console

            console = Console()
            monitor = SyncMonitor()
            monitor.update(take_sample())
            time.sleep(min(args.interval, 0.5))
            snapshot = monitor.update(take_sample())
            console.print(render_snapshot(snapshot, console.size.width, args.interval))
            return 0
        WatchSyncApp(args.interval).run()
        return 0
    except KeyboardInterrupt:
        return 130
    except SyncError as exc:
        from rich.console import Console

        Console(stderr=True).print(f"[red]{exc}[/]")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

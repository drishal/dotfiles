#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

from rich import box
from rich.console import Console, Group
from rich.panel import Panel
from rich.table import Table
from rich.text import Text
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Container
from textual.events import Resize
from textual.widgets import Footer, Header, Static

AMD_DEBUG_ROOT = Path("/sys/kernel/debug/dri")


@dataclass(frozen=True)
class GpuOption:
    kind: str
    identifier: str
    name: str


@dataclass(frozen=True)
class Metric:
    label: str
    value: str
    percent: float | None = None


@dataclass(frozen=True)
class Snapshot:
    title: str
    subtitle: str
    metrics: tuple[Metric, ...]
    details: tuple[str, ...] = ()


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
            value = os.environ.get(f"WATCH_GPU_{name}", fallback).strip()
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

class GpuError(RuntimeError):
    pass


def sudo_command(*args: str) -> list[str]:
    if sys.stdin.isatty():
        return ["sudo", *args]
    return ["sudo", "-n", *args]


def run(args: Sequence[str], *, timeout: float = 2.0, quiet: bool = True) -> str:
    try:
        proc = subprocess.run(
            args,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL if quiet else None,
            text=True,
            timeout=timeout,
        )
    except FileNotFoundError as exc:
        raise GpuError(f"missing command: {args[0]}") from exc
    except subprocess.TimeoutExpired as exc:
        raise GpuError(f"command timed out: {' '.join(args)}") from exc

    if proc.returncode != 0:
        raise GpuError(f"command failed: {' '.join(args)}")
    return proc.stdout


def detect_amd() -> list[GpuOption]:
    try:
        output = run(
            [
                *sudo_command(
                    "find",
                    str(AMD_DEBUG_ROOT),
                    "-maxdepth",
                    "2",
                    "-name",
                    "amdgpu_pm_info",
                    "-print",
                )
            ],
            timeout=5.0,
            quiet=not sys.stdin.isatty(),
        )
    except GpuError:
        return []

    gpus: list[GpuOption] = []
    for line in output.splitlines():
        path = Path(line)
        if path.name == "amdgpu_pm_info" and path.parent.name:
            gpu_id = path.parent.name
            gpus.append(GpuOption("amd", gpu_id, f"AMD card {gpu_id}"))
    return sorted(gpus, key=lambda gpu: gpu.identifier)


def detect_nvidia() -> list[GpuOption]:
    if shutil.which("nvidia-smi") is None:
        return []

    try:
        output = run(
            ["nvidia-smi", "--query-gpu=index,name", "--format=csv,noheader"],
            timeout=3.0,
        )
    except GpuError:
        return []

    gpus: list[GpuOption] = []
    for line in output.splitlines():
        index, _, name = line.partition(",")
        index = index.strip()
        name = name.strip() or f"NVIDIA card {index}"
        if index:
            gpus.append(GpuOption("nvidia", index, name))
    return gpus


def detect_gpus() -> list[GpuOption]:
    # Prefer AMD first to preserve the old behavior on systems where both probes work.
    return [*detect_amd(), *detect_nvidia()]


def choose_gpu(gpus: Sequence[GpuOption], requested: str | None) -> GpuOption:
    if not gpus:
        raise GpuError("No supported GPU detected (need AMD amdgpu debugfs or NVIDIA nvidia-smi).")

    if requested is not None:
        for gpu in gpus:
            if requested in {gpu.identifier, f"{gpu.kind}:{gpu.identifier}"}:
                return gpu
        choices = ", ".join(f"{gpu.kind}:{gpu.identifier}" for gpu in gpus)
        raise GpuError(f"GPU {requested!r} not found. Available: {choices}")

    if len(gpus) == 1 or shutil.which("fzf") is None or not sys.stdin.isatty():
        return gpus[0]

    rows = [f"{gpu.kind}:{gpu.identifier}\t{gpu.name}" for gpu in gpus]
    proc = subprocess.run(
        [
            "fzf",
            "--prompt=Select GPU > ",
            "--header=Found GPUs",
            "--height=40%",
            "--layout=reverse",
            "--border",
            "--with-nth=1,2",
        ],
        input="\n".join(rows),
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=False,
    )
    selected = proc.stdout.partition("\t")[0].strip()
    if proc.returncode != 0 or not selected:
        raise KeyboardInterrupt

    for gpu in gpus:
        if selected == f"{gpu.kind}:{gpu.identifier}":
            return gpu
    raise GpuError("Selected GPU disappeared.")


def read_amd_pm_info(gpu_id: str) -> str:
    path = AMD_DEBUG_ROOT / gpu_id / "amdgpu_pm_info"
    return run(sudo_command("cat", str(path)), timeout=3.0, quiet=not sys.stdin.isatty())


def parse_percent(value: str) -> float | None:
    match = re.search(r"(-?\d+(?:\.\d+)?)\s*%", value)
    if match is None:
        return None
    return float(match.group(1))

def format_bytes(value: int) -> str:
    units = ("B", "KiB", "MiB", "GiB", "TiB")
    amount = float(value)
    for unit in units:
        if amount < 1024.0 or unit == units[-1]:
            if unit == "B":
                return f"{int(amount)} {unit}"
            return f"{amount:.1f} {unit}"
        amount /= 1024.0


def parse_usage_percent(value: str) -> float | None:
    match = re.search(
        r"(-?\d+(?:\.\d+)?)\s*([KMGT]?i?B?|[KMGT])?[^0-9]+(?:of|/)[^0-9]+(-?\d+(?:\.\d+)?)\s*([KMGT]?i?B?|[KMGT])?",
        value,
        re.IGNORECASE,
    )
    if match is None:
        return None

    used = float(match.group(1))
    total = float(match.group(3))
    if total <= 0:
        return None
    return (used / total) * 100.0


def read_int(path: Path) -> int | None:
    try:
        return int(path.read_text().strip())
    except (FileNotFoundError, PermissionError, ValueError):
        return None


def drm_devices_with_vram() -> list[Path]:
    devices: list[Path] = []
    for card in sorted(Path("/sys/class/drm").glob("card[0-9]*")):
        device = card / "device"
        if (device / "mem_info_vram_used").exists() and (device / "mem_info_vram_total").exists():
            devices.append(device)
    return devices


def amd_vram_metric(gpu_id: str) -> Metric | None:
    exact = Path(f"/sys/class/drm/card{gpu_id}/device")
    devices = [exact] if exact.exists() else []
    devices.extend(device for device in drm_devices_with_vram() if device != exact)

    for device in devices:
        used = read_int(device / "mem_info_vram_used")
        total = read_int(device / "mem_info_vram_total")
        if used is not None and total is not None and total > 0:
            return Metric("VRAM usage", f"{format_bytes(used)} / {format_bytes(total)}", (used / total) * 100.0)

    return None



def parse_amd_snapshot(gpu: GpuOption, raw: str) -> Snapshot:
    metrics: list[Metric] = []
    details: list[str] = []
    found_vram = False

    for original_line in raw.splitlines():
        line = original_line.strip()
        if not line:
            continue

        if line.startswith("GPU Temperature:"):
            metrics.append(Metric("Temperature", line.split(":", 1)[1].strip()))
        elif line.startswith("GPU Load:"):
            value = line.split(":", 1)[1].strip()
            metrics.append(Metric("GPU load", value, parse_percent(value)))
        elif line.startswith("VRAM Usage:"):
            value = line.split(":", 1)[1].strip()
            metrics.append(Metric("VRAM usage", value, parse_usage_percent(value)))
            found_vram = True
        elif "average GPU" in line:
            metrics.append(Metric("Power", line))
        elif "SCLK" in line:
            metrics.append(Metric("Core clock", line))
        elif "MCLK" in line:
            metrics.append(Metric("Memory clock", line))
        elif "VDDGFX" in line:
            metrics.append(Metric("Core voltage", line))
        elif "VDDCI" in line:
            metrics.append(Metric("Memory voltage", line))
        else:
            details.append(line)

    vram = None if found_vram else amd_vram_metric(gpu.identifier)
    if vram is not None:
        metrics.insert(2 if len(metrics) >= 2 else len(metrics), vram)

    return Snapshot(
        title=f"watch-gpu • {gpu.name}",
        subtitle=time.strftime("%Y-%m-%d %H:%M:%S"),
        metrics=tuple(metrics),
        details=tuple(details),
    )


def nvidia_snapshot(gpu: GpuOption) -> Snapshot:
    output = run(
        [
            "nvidia-smi",
            "--query-gpu=timestamp,name,utilization.gpu,utilization.memory,temperature.gpu,power.draw,clocks.current.sm,clocks.current.memory,memory.used,memory.total,pstate",
            "--format=csv,noheader,nounits",
            "-i",
            gpu.identifier,
        ],
        timeout=3.0,
    )
    row = next((line for line in output.splitlines() if line.strip()), "")
    fields = [field.strip() for field in row.split(",")]
    if len(fields) != 11:
        raise GpuError("Unexpected nvidia-smi output.")

    timestamp, name, gpu_util, mem_util, temp, power, sm_clock, mem_clock, mem_used, mem_total, pstate = fields
    memory_percent = None
    try:
        used = float(mem_used)
        total = float(mem_total)
        memory_percent = (used / total) * 100 if total > 0 else None
    except ValueError:
        pass

    return Snapshot(
        title=f"watch-gpu • NVIDIA card {gpu.identifier}",
        subtitle=timestamp,
        metrics=(
            Metric("Name", name),
            Metric("P-state", pstate),
            Metric("Temperature", f"{temp} °C"),
            Metric("GPU load", f"{gpu_util}%", parse_percent(gpu_util)),
            Metric("Memory load", f"{mem_util}%", parse_percent(mem_util)),
            Metric("VRAM usage", f"{mem_used} / {mem_total} MiB", memory_percent),
            Metric("Power draw", f"{power} W"),
            Metric("Core clock", f"{sm_clock} MHz"),
            Metric("Memory clock", f"{mem_clock} MHz"),
        ),
    )


def get_snapshot(gpu: GpuOption) -> Snapshot:
    if gpu.kind == "amd":
        return parse_amd_snapshot(gpu, read_amd_pm_info(gpu.identifier))
    if gpu.kind == "nvidia":
        return nvidia_snapshot(gpu)
    raise GpuError(f"Unsupported GPU type: {gpu.kind}")


def bar_style(percent: float | None) -> str:
    if percent is None:
        return THEME.base0C
    if percent >= 85:
        return THEME.base08
    if percent >= 60:
        return THEME.base0A
    return THEME.base0B


def text_bar(percent: float, width: int) -> Text:
    percent = max(0.0, min(100.0, percent))
    width = max(1, width)
    filled = min(width, round((percent / 100.0) * width))
    text = Text()
    text.append("█" * filled, style=bar_style(percent))
    text.append("░" * (width - filled), style=THEME.base03)
    return text


def metric_table(snapshot: Snapshot, width: int) -> Table:
    compact = width < 70
    show_bars = width >= 48
    label_width = min(16, max(10, width // 4))
    bar_width = max(6, width - label_width - 20)

    table = Table.grid(expand=True)
    table.add_column("label", width=label_width, style="dim", no_wrap=True)
    table.add_column("value", ratio=1, overflow="fold")

    for metric in snapshot.metrics:
        if metric.percent is None:
            table.add_row(metric.label, metric.value)
            continue

        percent = max(0.0, min(100.0, metric.percent))
        if not show_bars:
            table.add_row(metric.label, f"{percent:>3.0f}%  {metric.value}")
            continue

        value = Text()
        value.append_text(text_bar(percent, bar_width))
        value.append(f" {percent:>3.0f}%", style="bold")
        if not compact:
            value.append(f"  {metric.value}", style="dim")
        table.add_row(metric.label, value)

    return table


def render_snapshot(snapshot: Snapshot, width: int, height: int, interval: float) -> Panel:
    compact = width < 70
    detail_limit = max(0, min(8, height - len(snapshot.metrics) - 9))
    body: list[object] = [metric_table(snapshot, width)]

    if snapshot.details and detail_limit:
        detail_table = Table.grid(expand=True)
        detail_table.add_column(style="dim", overflow="ellipsis", no_wrap=compact)
        for detail in snapshot.details[:detail_limit]:
            detail_table.add_row(detail)
        body.extend([Text(""), detail_table])

    return Panel(
        Group(*body),
        title=f"[bold {THEME.base0D}]{snapshot.title}[/]",
        subtitle=f"[{THEME.base03}]{snapshot.subtitle} • refresh {interval:g}s[/]",
        border_style=THEME.base0D,
        box=box.ROUNDED if width >= 40 else box.SIMPLE,
        padding=(0, 1) if compact else (1, 2),
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
        height = max(8, self.size.height)
        if self.error is not None:
            return Panel(
                Text(self.error, style=f"bold {THEME.base08}"),
                title=f"[bold {THEME.base08}]watch-gpu[/]",
                border_style=THEME.base08,
                box=box.ROUNDED if width >= 40 else box.SIMPLE,
            )
        if self.snapshot is None:
            return Panel("Detecting GPU…", title=f"[bold {THEME.base0D}]watch-gpu[/]", border_style=THEME.base0D)
        return render_snapshot(self.snapshot, width, height, self.interval)


class WatchGpuApp(App[None]):
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
        Binding("ctrl+c", "quit", "Quit", show=False),
    ]

    def __init__(self, gpu: GpuOption, interval: float) -> None:
        super().__init__()
        self.gpu = gpu
        self.interval = interval
        self.dashboard = Dashboard(interval)
        self.smoothed_gpu_load: float | None = None

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Container(id="frame"):
            yield self.dashboard
        yield Footer()

    def on_mount(self) -> None:
        self.title = "watch-gpu"
        self.sub_title = self.gpu.name
        self.update_snapshot()
        self.set_interval(self.interval, self.update_snapshot)

    def stabilize_snapshot(self, snapshot: Snapshot) -> Snapshot:
        metrics: list[Metric] = []
        for metric in snapshot.metrics:
            if metric.label != "GPU load" or metric.percent is None:
                metrics.append(metric)
                continue

            raw = max(0.0, min(100.0, metric.percent))
            previous = self.smoothed_gpu_load
            if previous is None:
                smoothed = raw
            else:
                # amdgpu's instantaneous load counter can alternate real samples
                # with zeroes at short polling intervals. Rise quickly, decay
                # slowly, so the dashboard reads like activity instead of a
                # strobe while still settling to 0 when the GPU is actually idle.
                alpha = 0.55 if raw > previous else 0.20
                smoothed = (alpha * raw) + ((1.0 - alpha) * previous)
                if raw == 0.0 and smoothed < 0.5:
                    smoothed = 0.0

            self.smoothed_gpu_load = smoothed
            metrics.append(Metric(metric.label, f"instant {metric.value}", smoothed))

        return Snapshot(snapshot.title, snapshot.subtitle, tuple(metrics), snapshot.details)

    def update_snapshot(self) -> None:
        try:
            self.dashboard.set_snapshot(self.stabilize_snapshot(get_snapshot(self.gpu)))
        except GpuError as exc:
            self.dashboard.set_error(str(exc))


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="watch-gpu",
        description="Pretty live GPU monitor for AMD amdgpu and NVIDIA GPUs.",
    )
    parser.add_argument("--gpu", help="GPU id to monitor, e.g. 0 or amd:0 or nvidia:0")
    parser.add_argument(
        "--interval",
        type=float,
        default=float(os.environ.get("WATCH_GPU_INTERVAL", "0.5")),
        help="Refresh interval in seconds (default: WATCH_GPU_INTERVAL or 0.5)",
    )
    parser.add_argument("--once", action="store_true", help="Render one snapshot and exit")
    return parser.parse_args(argv)


def main(argv: Sequence[str] = sys.argv[1:]) -> int:
    args = parse_args(argv)
    console = Console()

    if args.interval <= 0:
        Console(stderr=True).print("[red]--interval must be greater than zero[/]")
        return 2

    try:
        gpu = choose_gpu(detect_gpus(), args.gpu)
        snapshot = get_snapshot(gpu)
        if args.once:
            console.print(render_snapshot(snapshot, console.size.width, console.size.height, args.interval))
            return 0
        WatchGpuApp(gpu, args.interval).run()
        return 0
    except KeyboardInterrupt:
        return 130
    except GpuError as exc:
        Console(stderr=True).print(f"[red]{exc}[/]")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

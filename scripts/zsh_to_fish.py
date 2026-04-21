#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_ZSH_HISTORY = (
    SCRIPT_DIR / ".zsh_history"
    if (SCRIPT_DIR / ".zsh_history").exists()
    else SCRIPT_DIR / "zsh_history"
)
DEFAULT_FISH_HISTORY = SCRIPT_DIR / "fish_history"
HOME_ZSH_HISTORY = Path.home() / ".zsh_history"
HOME_FISH_HISTORY = Path.home() / ".local/share/fish/fish_history"
LARGE_HISTORY_SIZE = 1_000_000
EXTENDED_HISTORY_RE = re.compile(r"^:\s+\d+:\d+;(.*)$")
JSON_KEY_FRAGMENT_RE = re.compile(r"^\s*[\"'][^\"']+[\"']\s*:")


@dataclass
class FishEntry:
    command: str
    when: int = 0
    paths: list[str] = field(default_factory=list)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Sync command history between zsh and fish. By default this operates on the "
            "safe local copies next to this script, not your real shell history files."
        ),
        epilog=(
            f"Real files if you want them later: {HOME_ZSH_HISTORY} and {HOME_FISH_HISTORY}"
        ),
    )
    parser.add_argument(
        "--zsh-file",
        type=Path,
        default=DEFAULT_ZSH_HISTORY,
        help=f"zsh history file (default: {DEFAULT_ZSH_HISTORY})",
    )
    parser.add_argument(
        "--fish-file",
        type=Path,
        default=DEFAULT_FISH_HISTORY,
        help=f"fish history file (default: {DEFAULT_FISH_HISTORY})",
    )
    parser.add_argument(
        "--backup",
        action="store_true",
        help="create numbered backups named zsh_history_N and fish_history_N before writing",
    )
    return parser.parse_args()


def normalize_path(path: Path) -> Path:
    return path.expanduser()


def atomic_write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=str(path.parent))
    temp_path = Path(temp_name)
    try:
        if path.exists():
            temp_path.chmod(path.stat().st_mode)
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_path, path)
    finally:
        if temp_path.exists():
            temp_path.unlink()


def next_backup_path(target: Path, shell_name: str) -> Path:
    index = 1
    while True:
        candidate = target.parent / f"{shell_name}_history_{index}"
        if not candidate.exists():
            return candidate
        index += 1


def backup_file(target: Path, shell_name: str) -> Path | None:
    if not target.exists():
        return None
    backup_path = next_backup_path(target, shell_name)
    shutil.copy2(target, backup_path)
    return backup_path


def fish_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace("\n", "\\n")


def fish_unescape(value: str) -> str:
    result: list[str] = []
    index = 0
    while index < len(value):
        char = value[index]
        if char != "\\":
            result.append(char)
            index += 1
            continue

        if index + 1 >= len(value):
            result.append("\\")
            break

        next_char = value[index + 1]
        if next_char == "\\":
            result.append("\\")
        elif next_char == "n":
            result.append("\n")
        else:
            result.append("\\")
            result.append(next_char)
        index += 2

    return "".join(result)


def split_key_value(line: str) -> tuple[str, str] | None:
    if ":" not in line:
        return None
    key, value = line.split(":", 1)
    return key, value.lstrip()


def parse_fish_history(path: Path) -> list[FishEntry]:
    if not path.exists() or path.stat().st_size == 0:
        return []

    lines = path.read_bytes().decode("utf-8", "surrogateescape").splitlines()
    entries: list[FishEntry] = []
    index = 0

    while index < len(lines):
        line = lines[index].lstrip()
        if not line.startswith("- cmd"):
            index += 1
            continue

        parsed = split_key_value(line)
        if parsed is None:
            index += 1
            continue

        _, raw_command = parsed
        command = fish_unescape(raw_command)
        index += 1
        when = 0
        paths: list[str] = []
        indent: int | None = None

        while index < len(lines):
            current_line = lines[index]
            leading_spaces = len(current_line) - len(current_line.lstrip(" "))
            stripped = current_line[leading_spaces:]

            if leading_spaces == 0:
                break

            if indent is None:
                indent = leading_spaces

            if leading_spaces != indent:
                break

            parsed = split_key_value(stripped)
            if parsed is None:
                break

            key, value = parsed
            index += 1

            if key == "when":
                try:
                    when = int(value)
                except ValueError:
                    when = 0
            elif key == "paths":
                while index < len(lines):
                    path_line = lines[index]
                    child_spaces = len(path_line) - len(path_line.lstrip(" "))
                    stripped_path = path_line[child_spaces:]
                    if child_spaces <= indent or not stripped_path.startswith("- "):
                        break
                    paths.append(fish_unescape(stripped_path[2:]))
                    index += 1

        entries.append(FishEntry(command=command, when=when, paths=paths))

    return entries


def write_fish_history(path: Path, entries: list[FishEntry]) -> None:
    chunks: list[str] = []
    for entry in entries:
        chunks.append(f"- cmd: {fish_escape(entry.command)}\n")
        chunks.append(f"  when: {entry.when}\n")
        if entry.paths:
            chunks.append("  paths:\n")
            for item in entry.paths:
                chunks.append(f"    - {fish_escape(item)}\n")
    atomic_write_bytes(path, "".join(chunks).encode("utf-8", "surrogateescape"))


def detect_zsh_format(path: Path) -> str:
    if not path.exists() or path.stat().st_size == 0:
        return "plain"
    _, zsh_format = parse_zsh_history(path)
    return zsh_format


def run_subprocess(command: list[str], *, input_bytes: bytes | None = None) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        command,
        input=input_bytes,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )


def is_prompt_artifact(line: str) -> bool:
    stripped = line.lstrip()
    return stripped.startswith("discord>")


def is_json_like_fragment(line: str) -> bool:
    stripped = line.lstrip()
    if not stripped:
        return False
    if JSON_KEY_FRAGMENT_RE.match(stripped):
        return True
    if stripped in {"{", "}", "[", "]", "},", "],", "}'", "}'\\", "}'\\\\"}:
        return True
    return stripped.startswith(("}", "]"))


def buffer_has_json_context(lines: list[str]) -> bool:
    text = "\n".join(lines)
    return any(
        token in text
        for token in (
            "curl ",
            " -d ",
            " --data",
            " --json",
            " --data-raw",
            " --data-binary",
            " -H ",
            "\t-H ",
        )
    )


def should_continue_zsh(buffer_lines: list[str], next_line: str) -> bool:
    stripped = next_line.strip()
    if next_line == "" or stripped == "\\":
        return True
    if next_line.startswith((" ", "\t")):
        return True

    stripped = next_line.lstrip()
    if stripped.startswith(("-", "#")):
        return True
    if buffer_has_json_context(buffer_lines) and is_json_like_fragment(stripped):
        return True
    if stripped.startswith(('"', "'")) and not is_json_like_fragment(stripped):
        return True
    if stripped.endswith("\\") and stripped[:1] and stripped[:1] not in {'"', "'"}:
        return True
    if stripped in {"done", "fi", "esac", "}"}:
        return True
    return False


def is_unattached_fragment(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return False
    if stripped == "\\":
        return True
    return is_json_like_fragment(stripped)


def export_zsh_commands(path: Path) -> list[str]:
    script = r'''
emulate -L zsh
zmodload zsh/parameter
fc -p "$1" 1000000 1000000
integer count=$(( $(fc -ln 1 | wc -l) ))
for ((i = 1; i <= count; i++)); do
  printf '%s\0' "$history[$i]"
done
'''
    result = run_subprocess(["zsh", "-fic", script, "zsh", str(path)])
    if not result.stdout:
        return []
    chunks = result.stdout.split(b"\0")
    if chunks and chunks[-1] == b"":
        chunks.pop()
    return [chunk.decode("utf-8", "surrogateescape") for chunk in chunks]


def inspect_zsh_file(path: Path) -> tuple[list[str], str, bool]:
    if not path.exists() or path.stat().st_size == 0:
        return [], "plain", False

    raw_lines = path.read_bytes().decode("utf-8", "surrogateescape").splitlines()
    saw_plain = False
    saw_extended = False
    suspicious = False

    for index, line in enumerate(raw_lines):
        if not line.strip():
            continue

        if is_prompt_artifact(line):
            suspicious = True
            continue

        if EXTENDED_HISTORY_RE.match(line):
            saw_extended = True
            continue

        saw_plain = True

    if saw_plain and saw_extended:
        return raw_lines, "mixed", True
    if saw_extended:
        return raw_lines, "extended", suspicious
    return raw_lines, "plain", suspicious


def heuristic_parse_zsh_lines(raw_lines: list[str]) -> list[str]:
    commands: list[str] = []
    index = 0

    while index < len(raw_lines):
        line = raw_lines[index]

        if not line.strip() or is_prompt_artifact(line):
            index += 1
            continue

        match = EXTENDED_HISTORY_RE.match(line)
        if match:
            command = match.group(1)
            if command:
                commands.append(command)
            index += 1
            continue

        if is_unattached_fragment(line):
            index += 1
            continue

        buffer = [line]
        index += 1

        while buffer[-1].endswith("\\") and index < len(raw_lines):
            next_line = raw_lines[index]
            if is_prompt_artifact(next_line):
                break
            if not should_continue_zsh(buffer, next_line):
                break
            buffer[-1] = buffer[-1][:-1]
            if next_line == "" or next_line.strip() == "\\":
                buffer.append("")
            else:
                buffer.append(next_line)
            index += 1

        commands.append("\n".join(buffer))

    return commands


def parse_zsh_history(path: Path) -> tuple[list[str], str]:
    raw_lines, zsh_format, suspicious = inspect_zsh_file(path)
    if not raw_lines:
        return [], zsh_format

    if suspicious:
        return heuristic_parse_zsh_lines(raw_lines), zsh_format

    try:
        return export_zsh_commands(path), zsh_format
    except subprocess.CalledProcessError:
        return heuristic_parse_zsh_lines(raw_lines), zsh_format


def write_zsh_history_via_zsh(path: Path, commands: list[str], *, extended: bool) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=str(path.parent))
    os.close(fd)
    temp_path = Path(temp_name)
    try:
        input_bytes = b"\0".join(
            command.encode("utf-8", "surrogateescape") for command in commands
        )
        if input_bytes:
            input_bytes += b"\0"
        history_option = "setopt extended_history" if extended else "unsetopt extended_history"
        script = rf'''
emulate -L zsh
{history_option}
fc -p "$1" 1000000 1000000
while IFS= read -r -d '' cmd; do
  print -sr -- "$cmd"
done
fc -W "$1"
'''
        run_subprocess(
            ["zsh", "-fic", script, "zsh", str(temp_path)],
            input_bytes=input_bytes,
        )
        if path.exists():
            temp_path.chmod(path.stat().st_mode)
        os.replace(temp_path, path)
    finally:
        if temp_path.exists():
            temp_path.unlink()


def write_plain_zsh_history(path: Path, commands: list[str]) -> None:
    write_zsh_history_via_zsh(path, commands, extended=False)


def write_extended_zsh_history(path: Path, commands: list[str]) -> None:
    write_zsh_history_via_zsh(path, commands, extended=True)


def write_zsh_history(path: Path, commands: list[str], zsh_format: str) -> None:
    if zsh_format == "extended":
        write_extended_zsh_history(path, commands)
    else:
        write_plain_zsh_history(path, commands)


def normalize_command_for_merge(command: str) -> str:
    if command.startswith("\\:"):
        return command[1:]
    return command


def build_occurrence_keys(commands: list[str]) -> list[tuple[str, int]]:
    counts: defaultdict[str, int] = defaultdict(int)
    keys: list[tuple[str, int]] = []
    for command in commands:
        normalized = normalize_command_for_merge(command)
        counts[normalized] += 1
        keys.append((normalized, counts[normalized]))
    return keys


def merge_occurrence_keys(primary: list[tuple[str, int]], secondary: list[tuple[str, int]]) -> list[tuple[str, int]]:
    merged: list[tuple[str, int]] = []
    seen: set[tuple[str, int]] = set()
    for sequence in (primary, secondary):
        for key in sequence:
            if key in seen:
                continue
            seen.add(key)
            merged.append(key)
    return merged


def fish_entries_by_key(entries: list[FishEntry]) -> dict[tuple[str, int], FishEntry]:
    counts: defaultdict[str, int] = defaultdict(int)
    mapping: dict[tuple[str, int], FishEntry] = {}
    for entry in entries:
        counts[entry.command] += 1
        mapping[(entry.command, counts[entry.command])] = entry
    return mapping


def build_merged_fish_entries(merged_keys: list[tuple[str, int]], existing_entries: list[FishEntry]) -> list[FishEntry]:
    existing_by_key = fish_entries_by_key(existing_entries)
    next_when = max((entry.when for entry in existing_entries), default=0)
    next_when = max(next_when, int(time.time()))
    merged_entries: list[FishEntry] = []

    for key in merged_keys:
        existing = existing_by_key.get(key)
        if existing is not None:
            merged_entries.append(existing)
            continue
        next_when += 1
        merged_entries.append(FishEntry(command=key[0], when=next_when))

    return merged_entries


def sync_histories(zsh_path: Path, fish_path: Path, backup: bool) -> int:
    zsh_commands, zsh_format = parse_zsh_history(zsh_path)
    fish_entries = parse_fish_history(fish_path)
    fish_commands = [entry.command for entry in fish_entries]

    zsh_keys = build_occurrence_keys(zsh_commands)
    fish_keys = build_occurrence_keys(fish_commands)
    merged_keys = merge_occurrence_keys(fish_keys, zsh_keys)
    merged_commands = [command for command, _ in merged_keys]
    merged_fish_entries = build_merged_fish_entries(merged_keys, fish_entries)

    zsh_additions = len(merged_commands) - len(zsh_commands)
    fish_additions = len(merged_fish_entries) - len(fish_entries)

    if backup:
        zsh_backup = backup_file(zsh_path, "zsh")
        fish_backup = backup_file(fish_path, "fish")
        if zsh_backup is not None:
            print(f"zsh backup:  {zsh_backup}")
        if fish_backup is not None:
            print(f"fish backup: {fish_backup}")

    write_zsh_history(zsh_path, merged_commands, zsh_format)
    write_fish_history(fish_path, merged_fish_entries)

    write_mode = "extended" if zsh_format == "extended" else "plain"
    print(f"zsh format:   {zsh_format} -> {write_mode}")
    print(f"zsh entries:  {len(zsh_commands)} -> {len(merged_commands)} (+{zsh_additions})")
    print(f"fish entries: {len(fish_entries)} -> {len(merged_fish_entries)} (+{fish_additions})")
    print(f"synced files: {zsh_path} | {fish_path}")
    return 0


def main() -> int:
    args = parse_args()
    zsh_path = normalize_path(args.zsh_file)
    fish_path = normalize_path(args.fish_file)

    if not zsh_path.exists():
        print(f"zsh history file not found: {zsh_path}", file=sys.stderr)
        return 1

    if not fish_path.exists():
        print(f"fish history file not found: {fish_path}", file=sys.stderr)
        return 1

    try:
        return sync_histories(zsh_path, fish_path, args.backup)
    except subprocess.CalledProcessError as error:
        stderr = error.stderr.decode("utf-8", "replace") if error.stderr else ""
        print("zsh subprocess failed.", file=sys.stderr)
        if stderr:
            print(stderr.strip(), file=sys.stderr)
        return error.returncode or 1


if __name__ == "__main__":
    raise SystemExit(main())

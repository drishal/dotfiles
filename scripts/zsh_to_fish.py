#!/usr/bin/env python3
import argparse
import fcntl
import os
import re
import shutil
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path


EXTENDED_ZSH_RE = re.compile(r"^:\s*(\d+)(?::\d+)?;\s*(.*)$")


@dataclass
class ZshEntry:
    command: str
    timestamp: int | None
    raw_line: str


@dataclass
class FishEntry:
    command: str
    timestamp: int | None
    extra_lines: list[str]
    multiline: bool


def is_escaped(text: str, index: int) -> bool:
    backslashes = 0
    cursor = index - 1
    while cursor >= 0 and text[cursor] == "\\":
        backslashes += 1
        cursor -= 1
    return backslashes % 2 == 1


def normalize_history_command(command: str) -> str:
    result: list[str] = []
    in_single = False
    in_double = False
    index = 0

    while index < len(command):
        char = command[index]

        if char == "'" and not in_double and not is_escaped(command, index):
            in_single = not in_single
            result.append(char)
            index += 1
            continue

        if char == '"' and not in_single and not is_escaped(command, index):
            in_double = not in_double
            result.append(char)
            index += 1
            continue

        if not in_single and not in_double and char == "\\":
            slash_end = index
            while slash_end < len(command) and command[slash_end] == "\\":
                slash_end += 1
            if slash_end < len(command) and command[slash_end] == "n":
                space_end = slash_end + 1
                while space_end < len(command) and command[space_end] in " \t":
                    space_end += 1
                if not result or not result[-1].isspace():
                    result.append(" ")
                index = space_end
                continue

        if not in_single and not in_double and char == "\n":
            if not result or not result[-1].isspace():
                result.append(" ")
            index += 1
            while index < len(command) and command[index] in " \t":
                index += 1
            continue

        result.append(char)
        index += 1

    return "".join(result).strip()


def has_shell_quotes(command: str) -> bool:
    return any(char in command for char in ('"', "'"))


def zsh_to_fish_command(command: str) -> str:
    command = normalize_history_command(command)
    if has_shell_quotes(command):
        return command
    command = re.sub(r"\s*&&\s*", " ; and ", command)
    command = re.sub(r"\s*\|\|\s*", " ; or ", command)
    return command.strip()


def fish_to_zsh_command(command: str) -> str:
    command = normalize_history_command(command)
    if has_shell_quotes(command):
        return command
    command = re.sub(r"\s*;\s*and\s+", " && ", command)
    command = re.sub(r"\s*;\s*or\s+", " || ", command)
    return command.strip()


def is_reasonably_fish_compatible(command: str) -> bool:
    command = command.strip()
    if not command:
        return False

    disallowed = [
        r"^\s*[A-Za-z_][A-Za-z0-9_]*=.*$",
        r"\[\[",
        r"`",
        r"^\s*alias\s+",
        r"^\s*function\s+",
        r"^\s*if\b.*\bthen\b",
        r"^\s*for\b.*\bdo\b",
    ]
    return not any(re.search(pattern, command) for pattern in disallowed)


def is_reasonably_zsh_compatible(command: str) -> bool:
    command = command.strip()
    if not command:
        return False

    disallowed = [
        r"\s;\s*and\b",
        r"\s;\s*or\b",
        r"^\s*set\s+-",
        r"^\s*begin\b",
        r"^\s*end\b",
    ]
    return not any(re.search(pattern, command) for pattern in disallowed)


def read_zsh_history(path: Path) -> tuple[list[ZshEntry], str]:
    if not path.exists():
        return [], "plain"

    entries: list[ZshEntry] = []
    saw_extended = False
    saw_plain = False
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            raw_line = line.rstrip("\n")
            if not raw_line.strip():
                continue

            match = EXTENDED_ZSH_RE.match(raw_line)
            if match:
                saw_extended = True
                timestamp, command = match.groups()
                entries.append(
                    ZshEntry(
                        command=normalize_history_command(command.strip()),
                        timestamp=int(timestamp),
                        raw_line=raw_line,
                    )
                )
            else:
                saw_plain = True
                entries.append(
                    ZshEntry(
                        command=normalize_history_command(raw_line.strip()),
                        timestamp=None,
                        raw_line=raw_line,
                    )
                )

    if saw_extended and saw_plain:
        return entries, "mixed"

    return entries, ("extended" if saw_extended else "plain")


def read_fish_history(path: Path) -> list[FishEntry]:
    if not path.exists():
        return []

    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    entries: list[FishEntry] = []
    current_command: str | None = None
    current_timestamp: int | None = None
    current_extra_lines: list[str] = []
    current_multiline = False

    def flush() -> None:
        nonlocal \
            current_command, \
            current_timestamp, \
            current_extra_lines, \
            current_multiline
        if current_command is not None:
            entries.append(
                FishEntry(
                    command=normalize_history_command(current_command.strip()),
                    timestamp=current_timestamp,
                    extra_lines=current_extra_lines[:],
                    multiline=current_multiline,
                )
            )
        current_command = None
        current_timestamp = None
        current_extra_lines = []
        current_multiline = False

    index = 0
    while index < len(lines):
        line = lines[index]
        if line.startswith("- cmd: "):
            flush()
            current_command = line[len("- cmd: ") :]
            current_multiline = False
            index += 1
            continue

        if line == "- cmd: |":
            flush()
            current_multiline = True
            index += 1
            block_lines: list[str] = []
            while index < len(lines) and lines[index].startswith("    "):
                block_lines.append(lines[index][4:])
                index += 1
            current_command = "\n".join(block_lines)
            continue

        if current_command is None:
            index += 1
            continue

        current_extra_lines.append(line)
        stripped = line.strip()
        if stripped.startswith("when: "):
            value = stripped[len("when: ") :].strip()
            try:
                current_timestamp = int(value)
            except ValueError:
                current_timestamp = None
        index += 1

    flush()
    return entries


def render_zsh_entry(entry: ZshEntry, zsh_format: str) -> str:
    if zsh_format == "extended":
        timestamp = 0 if entry.timestamp is None else entry.timestamp
        return f": {timestamp}:0;{entry.command}"
    return entry.command


def render_fish_entry(entry: FishEntry) -> list[str]:
    if entry.multiline or "\n" in entry.command:
        lines = ["- cmd: |"]
        lines.extend(f"    {line}" for line in entry.command.splitlines())
    else:
        lines = [f"- cmd: {entry.command}"]

    if entry.extra_lines:
        lines.extend(entry.extra_lines)
        return lines

    timestamp = 0 if entry.timestamp is None else entry.timestamp
    lines.append(f"  when: {timestamp}")
    return lines


def make_backup(path: Path, suffix: str) -> Path | None:
    if not path.exists():
        return None
    backup_path = path.with_name(f"{path.name}{suffix}.{int(time.time())}")
    shutil.copy2(path, backup_path)
    return backup_path


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", dir=path.parent, delete=False
    ) as handle:
        handle.write(content)
        temp_path = Path(handle.name)
    os.replace(temp_path, path)


def lock_paths(paths: list[Path]) -> list[object]:
    lock_handles = []
    for path in sorted(paths):
        path.parent.mkdir(parents=True, exist_ok=True)
        handle = path.open("a+", encoding="utf-8")
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
        lock_handles.append(handle)
    return lock_handles


def unlock_paths(handles: list[object]) -> None:
    for handle in reversed(handles):
        fcntl.flock(handle.fileno(), fcntl.LOCK_UN)
        handle.close()


def append_missing_zsh_to_fish(
    zsh_entries: list[ZshEntry], fish_entries: list[FishEntry]
) -> tuple[list[FishEntry], int, int]:
    result = list(fish_entries)
    exact_keys = {(entry.command, entry.timestamp or 0) for entry in fish_entries}
    command_keys = {entry.command for entry in fish_entries}
    added = 0
    skipped = 0

    for entry in zsh_entries:
        command = zsh_to_fish_command(entry.command)
        if not is_reasonably_fish_compatible(command):
            skipped += 1
            continue

        if entry.timestamp is None:
            if command in command_keys:
                continue
            timestamp = 0
        else:
            timestamp = entry.timestamp

        key = (command, timestamp)
        if key in exact_keys:
            continue

        result.append(
            FishEntry(
                command=command,
                timestamp=timestamp,
                extra_lines=[f"  when: {timestamp}"],
                multiline=False,
            )
        )
        exact_keys.add(key)
        command_keys.add(command)
        added += 1

    return result, added, skipped


def append_missing_fish_to_zsh(
    fish_entries: list[FishEntry], zsh_entries: list[ZshEntry], zsh_format: str
) -> tuple[list[ZshEntry], int, int]:
    result = list(zsh_entries)
    if zsh_format == "extended":
        seen = {(entry.command, entry.timestamp or 0) for entry in zsh_entries}
    else:
        seen = {entry.command for entry in zsh_entries}

    added = 0
    skipped = 0

    for entry in fish_entries:
        command = fish_to_zsh_command(entry.command)
        if not is_reasonably_zsh_compatible(command):
            skipped += 1
            continue

        if zsh_format == "extended":
            key = (command, entry.timestamp or 0)
            if key in seen:
                continue
            seen.add(key)
            result.append(
                ZshEntry(command=command, timestamp=entry.timestamp or 0, raw_line="")
            )
        else:
            if command in seen:
                continue
            seen.add(command)
            result.append(ZshEntry(command=command, timestamp=None, raw_line=""))

        added += 1

    return result, added, skipped


def dedupe_zsh_entries(entries: list[ZshEntry], zsh_format: str) -> list[ZshEntry]:
    seen: set[object] = set()
    result: list[ZshEntry] = []
    for entry in entries:
        key: object
        if zsh_format == "extended":
            key = (entry.command, entry.timestamp or 0)
        else:
            key = entry.command
        if key in seen:
            continue
        seen.add(key)
        result.append(entry)
    return result


def dedupe_fish_entries(entries: list[FishEntry]) -> list[FishEntry]:
    seen: set[tuple[str, int]] = set()
    result: list[FishEntry] = []
    for entry in entries:
        key = (entry.command, entry.timestamp or 0)
        if key in seen:
            continue
        seen.add(key)
        result.append(entry)
    return result


def write_zsh_history(path: Path, entries: list[ZshEntry], zsh_format: str) -> None:
    content = "\n".join(render_zsh_entry(entry, zsh_format) for entry in entries)
    if content:
        content += "\n"
    atomic_write(path, content)


def write_fish_history(path: Path, entries: list[FishEntry]) -> None:
    lines: list[str] = []
    for entry in entries:
        lines.extend(render_fish_entry(entry))
    content = "\n".join(lines)
    if content:
        content += "\n"
    atomic_write(path, content)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Synchronize command history between zsh and fish."
    )
    parser.add_argument(
        "--zsh-history", type=Path, default=Path("~/.zsh_history").expanduser()
    )
    parser.add_argument(
        "--fish-history",
        type=Path,
        default=Path("~/.local/share/fish/fish_history").expanduser(),
    )
    parser.add_argument(
        "--zsh-format", choices=["auto", "plain", "extended"], default="auto"
    )
    parser.add_argument(
        "--write", action="store_true", help="Write changes back to the history files."
    )
    parser.add_argument(
        "--backup-suffix",
        default=".bak",
        help="Suffix to use when creating backups during --write.",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()

    locks = lock_paths([args.zsh_history, args.fish_history])
    try:
        zsh_entries, detected_zsh_format = read_zsh_history(args.zsh_history)
        fish_entries = read_fish_history(args.fish_history)
        zsh_format = (
            detected_zsh_format if args.zsh_format == "auto" else args.zsh_format
        )
        if zsh_format == "mixed":
            plain_count = sum(entry.timestamp is None for entry in zsh_entries)
            extended_count = len(zsh_entries) - plain_count
            zsh_format = "plain" if plain_count >= extended_count else "extended"

        merged_fish_entries, added_to_fish, skipped_for_fish = (
            append_missing_zsh_to_fish(zsh_entries, fish_entries)
        )
        merged_zsh_entries, added_to_zsh, skipped_for_zsh = append_missing_fish_to_zsh(
            fish_entries, zsh_entries, zsh_format
        )
        merged_fish_entries = dedupe_fish_entries(merged_fish_entries)
        merged_zsh_entries = dedupe_zsh_entries(merged_zsh_entries, zsh_format)

        print(f"zsh format: {zsh_format}")
        print(f"zsh entries: {len(zsh_entries)}")
        print(f"fish entries: {len(fish_entries)}")
        print(
            f"pending import into fish: {added_to_fish} (skipped incompatible: {skipped_for_fish})"
        )
        print(
            f"pending import into zsh: {added_to_zsh} (skipped incompatible: {skipped_for_zsh})"
        )

        if not args.write:
            print("Dry run only. Re-run with --write to modify files.")
            return 0

        zsh_backup = make_backup(args.zsh_history, args.backup_suffix)
        fish_backup = make_backup(args.fish_history, args.backup_suffix)
        write_zsh_history(args.zsh_history, merged_zsh_entries, zsh_format)
        write_fish_history(args.fish_history, merged_fish_entries)

        print(f"wrote zsh history: {args.zsh_history}")
        print(f"wrote fish history: {args.fish_history}")
        if zsh_backup:
            print(f"zsh backup: {zsh_backup}")
        if fish_backup:
            print(f"fish backup: {fish_backup}")
        return 0
    finally:
        unlock_paths(locks)


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3

import argparse
import os
import sys
import time
import yaml
from pathlib import Path
from typing import List, Set


def get_zsh_history_path() -> Path:
    return Path(os.environ.get("HISTFILE", Path.home() / ".zsh_history"))


def get_fish_history_path() -> Path:
    return Path.home() / ".local/share/fish/fish_history"


def read_zsh_history(history_file: Path) -> List[str]:
    """Read zsh history — properly handles multiline commands and extended format"""
    commands = []
    current_cmd = []
    in_entry = False

    try:
        with open(history_file, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                line = line.rstrip("\n")

                if line.startswith(": "):
                    # New entry begins → save previous if any
                    if current_cmd:
                        commands.append("\n".join(current_cmd))
                        current_cmd = []

                    # Parse timestamp + optional duration
                    # Examples: ": 1698765432:0;cmd" or ": 1698765432;cmd"
                    rest = line[2:].split(";", 1)
                    if len(rest) == 2:
                        cmd_part = rest[1]
                    else:
                        cmd_part = rest[0]  # rare no-duration case

                    current_cmd.append(cmd_part)
                    in_entry = True
                elif in_entry and line.strip():
                    # Continuation line of multiline command
                    current_cmd.append(line)
                elif line.strip():
                    # Legacy / no-timestamp line
                    commands.append(line)

        # Don't forget the last command
        if current_cmd:
            commands.append("\n".join(current_cmd))

    except FileNotFoundError:
        print(f"Warning: {history_file} not found", file=sys.stderr)

    return commands


def read_fish_history(history_file: Path) -> List[str]:
    """Read fish history — more robust: skips broken entries instead of failing"""
    commands = []
    try:
        with open(history_file, "r", encoding="utf-8", errors="ignore") as f:
            data = yaml.safe_load(f)
            if not isinstance(data, list):
                print("Warning: fish history root is not a list", file=sys.stderr)
                return commands

            for item in data:
                try:
                    if isinstance(item, dict):
                        cmd = item.get("cmd", "").strip()
                        if cmd:
                            commands.append(cmd)
                except Exception:
                    continue  # skip malformed entry

    except FileNotFoundError:
        print(f"Warning: {history_file} not found", file=sys.stderr)
    except yaml.YAMLError as e:
        print(f"Warning: Could not fully parse fish history: {e}", file=sys.stderr)
        print("    → Continuing with partial/empty source set", file=sys.stderr)
    except Exception as e:
        print(f"Unexpected error reading fish history: {e}", file=sys.stderr)

    return commands


def normalize_command(cmd: str) -> str:
    """Simple normalization for better deduplication"""
    return cmd.strip()


def get_unique_commands(source: List[str], target: List[str]) -> List[str]:
    """Return commands from source not present in target (after normalization)"""
    target_set: Set[str] = {normalize_command(c) for c in target}
    unique = []
    seen: Set[str] = set()

    for cmd in source:
        norm = normalize_command(cmd)
        if norm not in target_set and norm not in seen:
            unique.append(cmd)  # keep original form (with newlines if multiline)
            seen.add(norm)

    return unique


def write_zsh_history(commands: List[str], history_file: Path, append: bool = True) -> None:
    mode = "a" if append else "w"
    try:
        with open(history_file, mode, encoding="utf-8") as f:
            for cmd in commands:
                ts = int(time.time())
                # Write multiline as-is (zsh supports it)
                escaped_cmd = cmd.replace("\n", "\n")  # already correct
                f.write(f": {ts}:0;{escaped_cmd}\n")
    except Exception as e:
        print(f"Error writing to {history_file}: {e}", file=sys.stderr)
        sys.exit(1)


def write_fish_history(commands: List[str], history_file: Path, append: bool = True) -> None:
    existing = []
    if append and history_file.exists():
        try:
            with open(history_file, "r", encoding="utf-8", errors="ignore") as f:
                loaded = yaml.safe_load(f)
                if isinstance(loaded, list):
                    existing = loaded
        except Exception as e:
            print(f"Warning: Could not load existing fish history for append: {e}", file=sys.stderr)
            print("    → Starting fresh instead of appending", file=sys.stderr)

    new_entries = [{"cmd": cmd, "when": int(time.time())} for cmd in commands]

    combined = existing + new_entries if append else new_entries

    try:
        history_file.parent.mkdir(parents=True, exist_ok=True)
        with open(history_file, "w", encoding="utf-8") as f:
            yaml.dump(
                combined,
                f,
                default_flow_style=False,
                allow_unicode=True,
                sort_keys=False,
            )
    except Exception as e:
        print(f"Error writing to {history_file}: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Port command history between zsh and fish")
    parser.add_argument(
        "direction",
        choices=["zsh-to-fish", "fish-to-zsh"],
        help="Direction of history transfer",
    )
    parser.add_argument(
        "--overwrite", action="store_true", help="Overwrite destination (default: append)"
    )
    parser.add_argument("--zsh-history", help="Custom zsh history file path")
    parser.add_argument("--fish-history", help="Custom fish history file path")

    args = parser.parse_args()

    zsh_path = Path(args.zsh_history) if args.zsh_history else get_zsh_history_path()
    fish_path = Path(args.fish_history) if args.fish_history else get_fish_history_path()

    append_mode = not args.overwrite

    if args.direction == "zsh-to-fish":
        source = read_zsh_history(zsh_path)
        target = read_fish_history(fish_path)
        to_add = get_unique_commands(source, target)

        if to_add:
            print(f"Adding {len(to_add)} unique commands to fish history")
            write_fish_history(to_add, fish_path, append=append_mode)
        else:
            print("No new unique commands to add to fish")

    else:  # fish-to-zsh
        source = read_fish_history(fish_path)
        target = read_zsh_history(zsh_path)
        to_add = get_unique_commands(source, target)

        if to_add:
            print(f"Adding {len(to_add)} unique commands to zsh history")
            write_zsh_history(to_add, zsh_path, append=append_mode)
        else:
            print("No new unique commands to add to zsh")


if __name__ == "__main__":
    main()

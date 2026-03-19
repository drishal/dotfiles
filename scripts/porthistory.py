#!/usr/bin/env python3
"""
Simple zsh → fish history converter (one direction)
- Handles common zsh extended history format
- Skips dangerous/complex commands that usually break in fish
- Appends to fish_history
"""

import os
import re
import time
from pathlib import Path

def zsh_to_fish(cmd: str) -> str:
    """Very conservative conversion — add more rules as you need"""
    cmd = cmd.strip()
    # && → ; and
    cmd = re.sub(r'\s*&&\s*', ' ; and ', cmd)
    # || → ; or
    cmd = re.sub(r'\s*\|\|\s*', ' ; or ', cmd)
    # ; → ; (already fine in fish)
    return cmd


def looks_safe_for_fish(cmd: str) -> bool:
    """Very pragmatic filter — allow most real commands people use"""
    cmd = cmd.strip()

    # Skip empty
    if not cmd:
        return False

    # Skip lines that are clearly variable assignments only
    if re.match(r'^\s*[A-Za-z_][A-Za-z0-9_]*=.*$', cmd):
        if not any(c in cmd[cmd.index('='):] for c in ' ;|&('):
            return False

    # Skip lines starting with common fish-incompatible syntax
    bad_starts = [
        r'^\s*function\s',           # fish uses function name ... end
        r'^\s*if\s.*\sthen$',        # different structure
        r'^\s*for\s.*\sin\s',        # fish: for x in ...
        r'^alias ',                  # fish alias syntax is different
    ]
    for pat in bad_starts:
        if re.search(pat, cmd):
            return False

    # Allow most common command styles
    return True


def main():
    zsh_hist = Path("~/.zsh_history").expanduser()
    fish_hist = Path("~/.local/share/fish/fish_history").expanduser()

    if not zsh_hist.is_file():
        print("No ~/.zsh_history found")
        return

    fish_hist.parent.mkdir(parents=True, exist_ok=True)

    count = 0
    skipped = 0

    # We'll collect new entries and append once
    new_entries = []

    with zsh_hist.open('r', encoding='utf-8', errors='replace') as f:
        for line in f:
            line = line.rstrip('\n')

            # Two common zsh history formats
            m = re.match(r'^:\s*(\d+)(?::\d+)?;\s*(.*)$', line)
            if not m:
                # Try without space after first :
                m = re.match(r'^:(\d+)(?::\d+)?;\s*(.*)$', line)

            if not m:
                continue

            timestamp_str, command = m.groups()
            try:
                timestamp = int(timestamp_str)
            except ValueError:
                continue

            command = zsh_to_fish(command)

            if not looks_safe_for_fish(command):
                skipped += 1
                continue

            new_entries.append((command, timestamp))
            count += 1

    # Append mode — safe to run multiple times (fish ignores duplicates)
    with fish_hist.open('a', encoding='utf-8') as out:
        for cmd, ts in new_entries:
            out.write(f'- cmd: {cmd}\n')
            out.write(f'   when: {ts}\n')

    print(f"Done. Added {count} commands. Skipped {skipped} commands.")
    print(f"Written to: {fish_hist}")

    if count == 0:
        print("→ Probably no lines matched the zsh history format")


if __name__ == '__main__':
    main()

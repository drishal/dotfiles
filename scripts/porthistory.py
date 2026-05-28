#!/usr/bin/env python3
"""
zsh -> fish history converter (one direction)
- Handles zsh extended history format with backslash-continuation multi-line commands
- Dedups against existing fish_history (by cmd) so it's safe to re-run
- Appends to fish_history using canonical 2-space indent
"""

import re
from pathlib import Path


def zsh_to_fish(cmd: str) -> str:
    cmd = cmd.strip()
    cmd = re.sub(r'\s*&&\s*', ' ; and ', cmd)
    cmd = re.sub(r'\s*\|\|\s*', ' ; or ', cmd)
    return cmd


def looks_safe_for_fish(cmd: str) -> bool:
    cmd = cmd.strip()
    if not cmd:
        return False

    if re.match(r'^\s*[A-Za-z_][A-Za-z0-9_]*=.*$', cmd):
        if not any(c in cmd[cmd.index('='):] for c in ' ;|&('):
            return False

    bad_starts = [
        r'^\s*function\s',
        r'^\s*if\s.*\sthen$',
        r'^\s*for\s.*\sin\s',
        r'^alias ',
    ]
    for pat in bad_starts:
        if re.search(pat, cmd):
            return False

    return True


def read_zsh_entries(path: Path):
    """Yield (timestamp, command) tuples, joining backslash-continued lines."""
    entry_re = re.compile(r'^:\s*(\d+)(?::\d+)?;\s*(.*)$')

    with path.open('r', encoding='utf-8', errors='replace') as f:
        raw_lines = f.read().split('\n')

    i = 0
    while i < len(raw_lines):
        line = raw_lines[i]
        m = entry_re.match(line)
        if not m:
            i += 1
            continue

        ts_str, cmd = m.groups()

        # Trailing backslash = shell line continuation. zsh may store it as `\\`
        # (metafied) or `\` (non-extended). Join until neither form remains AND
        # the next line isn't a new `:ts;` entry.
        next_is_entry = lambda j: j < len(raw_lines) and entry_re.match(raw_lines[j])
        while cmd.endswith('\\') and i + 1 < len(raw_lines) and not next_is_entry(i + 1):
            strip = 2 if cmd.endswith('\\\\') else 1
            i += 1
            cmd = cmd[:-strip] + '\n' + raw_lines[i]

        try:
            ts = int(ts_str)
        except ValueError:
            i += 1
            continue

        yield ts, cmd
        i += 1


def fish_escape(cmd: str) -> str:
    """Escape command for fish_history YAML-ish format."""
    # fish encodes embedded newlines and backslashes
    return cmd.replace('\\', '\\\\').replace('\n', '\\n')


def existing_fish_cmds(path: Path) -> set:
    """Return set of already-present (decoded) commands in fish_history."""
    cmds = set()
    if not path.is_file():
        return cmds
    cmd_re = re.compile(r'^- cmd: (.*)$')
    with path.open('r', encoding='utf-8', errors='replace') as f:
        for line in f:
            m = cmd_re.match(line.rstrip('\n'))
            if m:
                cmds.add(m.group(1))
    return cmds


def main():
    zsh_hist = Path("~/.zsh_history").expanduser()
    fish_hist = Path("~/.local/share/fish/fish_history").expanduser()

    if not zsh_hist.is_file():
        print(f"No {zsh_hist} found")
        return

    fish_hist.parent.mkdir(parents=True, exist_ok=True)

    existing = existing_fish_cmds(fish_hist)

    added = 0
    skipped_unsafe = 0
    skipped_dup = 0
    new_entries = []
    seen_in_batch = set()

    for ts, cmd in read_zsh_entries(zsh_hist):
        cmd = zsh_to_fish(cmd)
        if not looks_safe_for_fish(cmd):
            skipped_unsafe += 1
            continue

        encoded = fish_escape(cmd)
        if encoded in existing or encoded in seen_in_batch:
            skipped_dup += 1
            continue

        seen_in_batch.add(encoded)
        new_entries.append((encoded, ts))
        added += 1

    with fish_hist.open('a', encoding='utf-8') as out:
        for cmd, ts in new_entries:
            out.write(f'- cmd: {cmd}\n')
            out.write(f'  when: {ts}\n')

    print(f"Done. Added {added}. Skipped unsafe {skipped_unsafe}. Skipped duplicates {skipped_dup}.")
    print(f"Written to: {fish_hist}")


if __name__ == '__main__':
    main()

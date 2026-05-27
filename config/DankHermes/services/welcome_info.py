#!/usr/bin/env python3
"""Emit a JSON dashboard summary for the DankHermes welcome screen.

Pulls data from the local `hermes` CLI and ~/.hermes/skills so the chat
landing page can show available toolsets, skill categories, and MCP
servers without hard-coding anything. Designed to fail soft — any
sub-call that errors out just leaves its section empty.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

# Friendly metadata per built-in toolset. Material Symbol names map to the
# icons DMS already ships with via DankIcon. Add/remove freely.
TOOLSET_META = {
    "web":             ("search",          "Web"),
    "browser":         ("language",        "Browser"),
    "terminal":        ("terminal",        "Terminal"),
    "file":            ("folder",          "Files"),
    "code_execution":  ("bolt",            "Code"),
    "vision":          ("visibility",      "Vision"),
    "video":           ("movie",           "Video"),
    "image_gen":       ("palette",         "Image Gen"),
    "video_gen":       ("videocam",        "Video Gen"),
    "x_search":        ("alternate_email", "X / Twitter"),
    "moa":             ("psychology",      "Mixture of Agents"),
    "tts":             ("graphic_eq",      "Text-to-Speech"),
    "skills":          ("auto_awesome",    "Skills"),
    "todo":            ("checklist",       "Todo"),
    "memory":          ("memory",          "Memory"),
    "session_search":  ("history",         "Session Search"),
    "clarify":         ("help",            "Clarify"),
    "delegation":      ("groups",          "Delegate"),
    "cronjob":         ("schedule",        "Cron"),
    "messaging":       ("chat",            "Messaging"),
    "homeassistant":   ("home",            "Home Assistant"),
    "spotify":         ("library_music",   "Spotify"),
    "yuanbao":         ("smart_toy",       "Yuanbao"),
    "computer_use":    ("mouse",           "Computer Use"),
}


def run(cmd, timeout=4):
    try:
        return subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout
        )
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return None


def parse_version():
    info = {"version": "", "updateAvailable": ""}
    res = run(["hermes", "version"])
    if not res or res.returncode != 0:
        return info
    for line in res.stdout.splitlines():
        m = re.match(r"Hermes Agent\s+v?(\S+)\s*(\([^)]+\))?", line)
        if m:
            info["version"] = m.group(1) + (" " + m.group(2) if m.group(2) else "")
            continue
        m = re.match(r"Update available:\s*(.+)$", line)
        if m:
            info["updateAvailable"] = m.group(1).strip()
    return info


def parse_toolsets():
    """Parse `hermes tools list` into a list of toolset dicts.

    Each entry: {name, label, icon, enabled}. Order preserved from CLI.
    """
    res = run(["hermes", "tools", "list", "--platform", "cli"])
    out = []
    if not res or res.returncode != 0:
        return out
    line_re = re.compile(r"^\s*(✓ enabled|✗ disabled)\s+(\S+)\s+(.*)$")
    for raw in res.stdout.splitlines():
        m = line_re.match(raw)
        if not m:
            continue
        name = m.group(2)
        enabled = m.group(1).startswith("✓")
        icon, label = TOOLSET_META.get(name, ("build", name.replace("_", " ").title()))
        out.append({
            "name": name,
            "label": label,
            "icon": icon,
            "enabled": enabled,
        })
    return out


def parse_mcp_servers():
    """Parse `hermes mcp list` for MCP server names + status."""
    res = run(["hermes", "mcp", "list"])
    out = []
    if not res or res.returncode != 0:
        return out
    # Strip ANSI just in case
    txt = re.sub(r"\x1b\[[0-9;]*m", "", res.stdout)
    started = False
    for raw in txt.splitlines():
        s = raw.rstrip()
        if not s:
            continue
        if not started:
            # First non-header, non-separator line after the column headers
            if re.match(r"^\s*Name\s+Transport", s):
                started = True
            continue
        if re.match(r"^\s*[─-]+", s):
            continue
        parts = s.split()
        if not parts:
            continue
        name = parts[0]
        # Cheap status detection
        enabled = "enabled" in s or "✓" in s
        out.append({"name": name, "enabled": enabled})
    return out


def scan_skills():
    """Enumerate installed skills from ~/.hermes/skills/<category>/<name>."""
    base = Path(os.path.expanduser("~/.hermes/skills"))
    if not base.is_dir():
        return {"total": 0, "categories": []}
    categories = []
    total = 0
    # Top-level entries — categories are directories; bare files / non-dirs are
    # uncategorized skills (e.g. find-skills symlink).
    uncategorized = []
    for entry in sorted(base.iterdir()):
        try:
            if entry.name.startswith("."):
                continue
            if entry.is_symlink() and not entry.exists():
                continue
            if not entry.is_dir():
                continue
        except OSError:
            continue

        # Detect whether `entry` is a category folder (contains skill subdirs)
        # or a single uncategorized skill.
        children = []
        try:
            for sub in sorted(entry.iterdir()):
                if sub.name.startswith("."):
                    continue
                if sub.is_dir() or (sub.is_symlink() and sub.exists()):
                    children.append(sub.name)
        except OSError:
            continue

        # Heuristic: if entry has SKILL.md / skill.md directly, it's a skill itself.
        has_skill_marker = any(
            (entry / f).exists() for f in ("SKILL.md", "skill.md", "DESCRIPTION.md")
        )
        if has_skill_marker and not children:
            uncategorized.append(entry.name)
            total += 1
        elif children:
            categories.append({"category": entry.name, "skills": children, "count": len(children)})
            total += len(children)
        else:
            uncategorized.append(entry.name)
            total += 1

    if uncategorized:
        categories.append({"category": "uncategorized", "skills": uncategorized, "count": len(uncategorized)})

    return {"total": total, "categories": categories}


def main():
    info = {
        **parse_version(),
        "toolsets": parse_toolsets(),
        "skills": scan_skills(),
        "mcpServers": parse_mcp_servers(),
    }
    info["hermesHome"] = os.path.expanduser(os.environ.get("HERMES_HOME", "~/.hermes"))
    json.dump(info, sys.stdout)


if __name__ == "__main__":
    main()

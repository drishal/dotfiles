"""Dashboard summary for the empty-chat welcome screen.

Ported from welcome_info.py. Calls the `hermes` CLI and scans ~/.hermes/skills.
Fails soft — any sub-call that errors leaves its section empty.
"""
from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

# Material Symbol name + label per built-in toolset.
TOOLSET_META = {
    "web": ("search", "Web"),
    "browser": ("language", "Browser"),
    "terminal": ("terminal", "Terminal"),
    "file": ("folder", "Files"),
    "code_execution": ("bolt", "Code"),
    "vision": ("visibility", "Vision"),
    "video": ("movie", "Video"),
    "image_gen": ("palette", "Image Gen"),
    "video_gen": ("videocam", "Video Gen"),
    "x_search": ("alternate_email", "X / Twitter"),
    "moa": ("psychology", "Mixture of Agents"),
    "tts": ("graphic_eq", "Text-to-Speech"),
    "skills": ("auto_awesome", "Skills"),
    "todo": ("checklist", "Todo"),
    "memory": ("memory", "Memory"),
    "session_search": ("history", "Session Search"),
    "clarify": ("help", "Clarify"),
    "delegation": ("groups", "Delegate"),
    "cronjob": ("schedule", "Cron"),
    "messaging": ("chat", "Messaging"),
    "homeassistant": ("home", "Home Assistant"),
    "spotify": ("library_music", "Spotify"),
    "yuanbao": ("smart_toy", "Yuanbao"),
    "computer_use": ("mouse", "Computer Use"),
}


def _run(cmd, timeout=4):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return None


def _parse_version() -> dict:
    info = {"version": "", "updateAvailable": ""}
    res = _run(["hermes", "version"])
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


def _parse_toolsets() -> list[dict]:
    res = _run(["hermes", "tools", "list", "--platform", "cli"])
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
        out.append({"name": name, "label": label, "icon": icon, "enabled": enabled})
    return out


def _parse_mcp_servers() -> list[dict]:
    res = _run(["hermes", "mcp", "list"])
    out = []
    if not res or res.returncode != 0:
        return out
    txt = re.sub(r"\x1b\[[0-9;]*m", "", res.stdout)
    started = False
    for raw in txt.splitlines():
        s = raw.rstrip()
        if not s:
            continue
        if not started:
            if re.match(r"^\s*Name\s+Transport", s):
                started = True
            continue
        if re.match(r"^\s*[─-]+", s):
            continue
        parts = s.split()
        if not parts:
            continue
        out.append({"name": parts[0], "enabled": "enabled" in s or "✓" in s})
    return out


def _scan_skills(hermes_home: str) -> dict:
    base = Path(os.path.expanduser(hermes_home)) / "skills"
    if not base.is_dir():
        return {"total": 0, "categories": []}
    categories = []
    uncategorized = []
    total = 0
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
        children = []
        try:
            for sub in sorted(entry.iterdir()):
                if sub.name.startswith("."):
                    continue
                if sub.is_dir() or (sub.is_symlink() and sub.exists()):
                    children.append(sub.name)
        except OSError:
            continue
        has_marker = any(
            (entry / f).exists() for f in ("SKILL.md", "skill.md", "DESCRIPTION.md")
        )
        if has_marker and not children:
            uncategorized.append(entry.name)
            total += 1
        elif children:
            categories.append(
                {"category": entry.name, "skills": children, "count": len(children)}
            )
            total += len(children)
        else:
            uncategorized.append(entry.name)
            total += 1
    if uncategorized:
        categories.append(
            {
                "category": "uncategorized",
                "skills": uncategorized,
                "count": len(uncategorized),
            }
        )
    return {"total": total, "categories": categories}


def gather(hermes_home: str = "~/.hermes") -> dict:
    info = {
        **_parse_version(),
        "toolsets": _parse_toolsets(),
        "skills": _scan_skills(hermes_home),
        "mcpServers": _parse_mcp_servers(),
        "hermesHome": os.path.expanduser(hermes_home),
    }
    return info

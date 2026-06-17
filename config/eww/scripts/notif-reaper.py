#!/usr/bin/env python3
"""Auto-expire action-less end-rs notifications.

end-rs is configured with every timeout = 0 (never auto-close) so that a
notification carrying actions stays on screen until the user responds (clicks
an action) or dismisses it with the popup's close button. That would make
*every* notification sticky, so this reaper restores normal auto-dismiss for
the ones WITHOUT actions: it polls end-rs's `end-notifications` var, tracks
when each id first appeared, and runs `end-rs close <id>` once an action-less
notification has outlived its urgency's timeout.

Runs as an eww `deflisten` (so eww owns its lifecycle and restarts it on
reload). Notifications with actions are never reaped — only the user closes
them. Critical notifications never auto-close either (matches end-rs's old
`critical = 0`).
"""
import json, os, re, signal, subprocess, sys, time

EWW = os.environ.get("EWW_CMD") or "eww"
# seconds before an action-less notification is closed, by urgency (None=never)
TTL = {"low": 5, "normal": 10, "critical": None}
POLL = 1.0

first_seen = {}


def extract(s):
    """Pull each `:notification '{...}'` JSON object out of the var literal,
    brace-counting so nested objects in the actions array don't trip us up."""
    res, key, idx = [], ":notification '", 0
    while True:
        i = s.find(key, idx)
        if i < 0:
            break
        j = i + len(key)
        if j >= len(s) or s[j] != "{":
            idx = j
            continue
        depth = k = 0
        k = j
        instr = esc = False
        while k < len(s):
            c = s[k]
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                instr = not instr
            elif not instr:
                if c == "{":
                    depth += 1
                elif c == "}":
                    depth -= 1
                    if depth == 0:
                        k += 1
                        break
            k += 1
        try:
            res.append(json.loads(s[j:k]))
        except Exception:
            pass
        idx = k
    return res


def get_notifs():
    try:
        out = subprocess.run([EWW, "get", "end-notifications"],
                             capture_output=True, text=True, timeout=3).stdout
    except Exception:
        return []
    return extract(out)


# singleton — drop older reapers so eww reloads don't stack pollers. Only
# SIGTERM sibling *python* processes: `pgrep -f notif-reaper.py` also matches
# the shell/wrapper that launched us, and killing that takes us down too.
def _kill_siblings():
    try:
        pids = subprocess.check_output(["pgrep", "-f", "notif-reaper.py"]).split()
    except Exception:
        return
    me = os.getpid()
    for p in pids:
        pid = int(p)
        if pid == me:
            continue
        try:
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                argv0 = os.path.basename(f.read().split(b"\0", 1)[0])
        except Exception:
            continue
        if b"python" in argv0:
            try:
                os.kill(pid, signal.SIGTERM)
            except Exception:
                pass


_kill_siblings()

signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
signal.signal(signal.SIGINT, lambda *_: sys.exit(0))

print("ok", flush=True)  # satisfy the deflisten's initial value

while True:
    now = time.time()
    live = set()
    for n in get_notifs():
        nid = n.get("id")
        if nid is None:
            continue
        live.add(nid)
        first_seen.setdefault(nid, now)
        if n.get("actions"):
            continue  # actionable → sticky, the user decides
        ttl = TTL.get(n.get("urgency", "normal"), 10)
        if ttl is not None and now - first_seen[nid] >= ttl:
            subprocess.run(["end-rs", "close", str(nid)], capture_output=True)
    for k in [k for k in first_seen if k not in live]:
        del first_seen[k]
    time.sleep(POLL)

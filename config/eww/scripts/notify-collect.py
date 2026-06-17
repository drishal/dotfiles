#!/usr/bin/env python3
"""Eww notification collector.

Eavesdrops the session bus for `org.freedesktop.Notifications.Notify` calls via
`dbus-monitor`. This coexists with the real notification daemon (end-rs, which
owns the bus name) because it never owns the name — it only snoops, feeding the
custom notification-center + calendar panel (the `notes` window). On-screen
popups are end-rs's job, not this script's.

Keeps a capped, persisted history and prints it as a JSON array to stdout on
every change, so an eww `deflisten` stays live. Signals:
  SIGUSR1  → clear history (the "Clear" button)
  SIGTERM/SIGINT → kill the dbus-monitor child and exit (no orphans)
"""
import json, os, re, signal, subprocess, sys, time

CACHE = os.path.expanduser("~/.cache/eww/notifications.json")
CAP = 50
os.makedirs(os.path.dirname(CACHE), exist_ok=True)


def load():
    try:
        with open(CACHE) as f:
            data = json.load(f)
            return data if isinstance(data, list) else []
    except Exception:
        return []


hist = load()

# singleton — terminate older collectors (each one's SIGTERM handler kills its
# own dbus-monitor child) so eww reloads don't stack eavesdroppers.
try:
    for pid in subprocess.check_output(["pgrep", "-f", "notify-collect.py"]).split():
        if int(pid) != os.getpid():
            os.kill(int(pid), signal.SIGTERM)
except Exception:
    pass


def emit():
    sys.stdout.write(json.dumps(hist) + "\n")
    sys.stdout.flush()


def save():
    try:
        with open(CACHE, "w") as f:
            json.dump(hist, f)
    except Exception:
        pass


def clear(*_):
    global hist
    hist = []
    save()
    emit()


proc = None


def shutdown(*_):
    if proc and proc.poll() is None:
        proc.terminate()
    sys.exit(0)


signal.signal(signal.SIGUSR1, clear)
signal.signal(signal.SIGTERM, shutdown)
signal.signal(signal.SIGINT, shutdown)

emit()  # show persisted history immediately

STR = re.compile(r'^\s*string "(.*)"\s*$')


def unescape(s):
    return s.replace('\\"', '"').replace("\\\\", "\\")


proc = subprocess.Popen(
    ["dbus-monitor",
     "interface='org.freedesktop.Notifications',member='Notify'"],
    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)

# Notify(app_name, replaces_id, app_icon, summary, body, actions, hints, exp)
# → the first four `string` args are app_name, app_icon, summary, body.
strings, collecting = [], False
for line in proc.stdout:
    if "member=Notify" in line:
        strings, collecting = [], True
        continue
    if not collecting:
        continue
    m = STR.match(line)
    if m:
        strings.append(unescape(m.group(1)))
        if len(strings) >= 4:
            collecting = False
            app, icon, summary, body = strings[:4]
            if not summary and not body:
                continue
            hist.insert(0, {
                "app": app or "Notification",
                "icon": icon or "",
                "summary": summary or "",
                "body": body or "",
                "time": time.strftime("%H:%M"),
                "ts": int(time.time()),
            })
            del hist[CAP:]
            save()
            emit()

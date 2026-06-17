#!/usr/bin/env bash
# Stream the calendar JSON for the currently-selected month offset. Re-emits on
# SIGUSR1, which cal-nav.sh raises after writing a new offset (same
# deflisten + signal pattern as the notification collector).
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
offfile="${XDG_CACHE_HOME:-$HOME/.cache}/eww/caloffset"
mkdir -p "$(dirname "$offfile")"
[ -f "$offfile" ] || echo 0 >"$offfile"

# singleton — kill any older streamer so eww reloads don't stack instances
for p in $(pgrep -f cal-stream.sh); do [ "$p" != "$$" ] && kill "$p" 2>/dev/null; done

emit() { python3 "$here/cal-month.py" "$(cat "$offfile" 2>/dev/null || echo 0)"; }
cleanup() { kill "${sleeper:-0}" 2>/dev/null; exit 0; }

trap emit USR1
trap cleanup TERM INT
emit
# idle, but stay interruptible so the USR1 trap can fire promptly
while :; do sleep 86400 & sleeper=$!; wait "$sleeper"; done

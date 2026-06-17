#!/usr/bin/env bash
# Start eww cleanly: kill stale instances, start the notification daemon
# (end-rs), then open the bar. The control center (dashboard) and power menu
# stay closed — toggle them from the bar.
set -euo pipefail

# Kill stale end-rs daemon (if any) so eww reloads don't stack instances.
pkill end-rs 2>/dev/null || true
end-rs daemon &

# Kill stale eww daemon and open fresh.
eww kill 2>/dev/null || true
sleep 0.3
# `eww open` auto-spawns the daemon if it isn't running.
eww open bar

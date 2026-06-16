#!/usr/bin/env bash
# Start eww cleanly: a single daemon with ONLY the bar open. The control
# center (dashboard) and power menu stay closed — toggle them from the bar
# (clock / sliders button → dashboard, power glyph → powermenu).
#
# Usage: scripts/launch.sh   (or bind it once you're ready to wire Hyprland)
set -euo pipefail

eww kill 2>/dev/null || true
sleep 0.3
# `eww open` auto-spawns the daemon if it isn't running.
eww open bar

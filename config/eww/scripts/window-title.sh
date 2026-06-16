#!/usr/bin/env bash
# Stream the focused window title for the bar. Same event-driven pattern as
# workspaces.sh, with a polling fallback.
set -euo pipefail

emit() {
  command -v hyprctl >/dev/null 2>&1 || { echo ""; return; }
  # App name = window class, title-cased (e.g. "firefox" -> "Firefox").
  hyprctl activewindow -j 2>/dev/null \
    | jq -r '.class // ""' 2>/dev/null \
    | sed 's/.*/\u&/' | head -c 40
  echo
}

emit

sig=${HYPRLAND_INSTANCE_SIGNATURE:-}
sock="${XDG_RUNTIME_DIR}/hypr/${sig}/.socket2.sock"

if [ -n "$sig" ] && command -v socat >/dev/null 2>&1 && [ -S "$sock" ]; then
  socat -U - "UNIX-CONNECT:${sock}" 2>/dev/null | while read -r line; do
    case "$line" in
      activewindow*|closewindow*|openwindow*|focusedmon*|fullscreen*) emit ;;
    esac
  done
else
  while sleep 1; do emit; done
fi

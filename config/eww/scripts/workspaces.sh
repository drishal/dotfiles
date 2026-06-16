#!/usr/bin/env bash
# Emit the Hyprland workspace list as a JSON array for the bar, and re-emit on
# every compositor event. Falls back to polling if socat isn't available, and
# to an empty list off Hyprland so the bar never crashes.
set -euo pipefail

emit() {
  command -v hyprctl >/dev/null 2>&1 || { echo '[]'; return; }
  local act
  act=$(hyprctl activeworkspace -j 2>/dev/null | jq '.id' 2>/dev/null || echo 0)
  hyprctl workspaces -j 2>/dev/null \
    | jq -c --argjson act "${act:-0}" \
        'sort_by(.id) | map({id: .id, windows: .windows, active: (.id == $act)})' \
        2>/dev/null || echo '[]'
}

emit

sig=${HYPRLAND_INSTANCE_SIGNATURE:-}
sock="${XDG_RUNTIME_DIR}/hypr/${sig}/.socket2.sock"

if [ -n "$sig" ] && command -v socat >/dev/null 2>&1 && [ -S "$sock" ]; then
  socat -U - "UNIX-CONNECT:${sock}" 2>/dev/null | while read -r line; do
    case "$line" in
      workspace*|createworkspace*|destroyworkspace*|focusedmon*|openwindow*|closewindow*|movewindow*)
        emit ;;
    esac
  done
else
  while sleep 1; do emit; done
fi

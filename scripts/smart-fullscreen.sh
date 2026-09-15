#!/usr/bin/env bash
set -euo pipefail

# MOD+F: `fullscreen_state {internal=2, client=0}` covers the screen but tells
# the client it is still windowed, so Chromium-based apps keep their UI (no F11
# presentation mode). Everything else gets the plain fullscreen toggle.
# This Hyprland build routes hyprctl dispatch through the Lua config, so the
# dispatcher must be passed as one `hl.dsp.*` expression string.

info=$(hyprctl -j activewindow 2>/dev/null || true)
[ -n "$info" ] || exit 0

class=$(jq -r '.class // ""' <<<"$info")
fs=$(jq -r '.fullscreen // 0' <<<"$info")

case "$class" in
  brave*)
    if [ "$fs" -eq 2 ]; then
      hyprctl dispatch 'hl.dsp.window.fullscreen_state({ internal = 0, client = 0 })' >/dev/null
    else
      hyprctl dispatch 'hl.dsp.window.fullscreen_state({ internal = 2, client = 0 })' >/dev/null
    fi
    ;;
  *) hyprctl dispatch 'hl.dsp.window.fullscreen({ action = "toggle" })' >/dev/null ;;
esac

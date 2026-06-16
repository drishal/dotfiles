#!/usr/bin/env bash
# Audio control via wireplumber (wpctl) — always present under pipewire.
set -euo pipefail

SINK="@DEFAULT_AUDIO_SINK@"
SRC="@DEFAULT_AUDIO_SOURCE@"

case "${1:-get}" in
  get)
    wpctl get-volume "$SINK" | awk '{ printf "%d", $2 * 100 }'
    ;;
  muted)
    wpctl get-volume "$SINK" | grep -q MUTED && echo true || echo false
    ;;
  set)
    wpctl set-volume "$SINK" "${2:-0}%"
    ;;
  toggle)
    wpctl set-mute "$SINK" toggle
    ;;
  sink)
    # short friendly name of the default sink
    wpctl inspect "$SINK" 2>/dev/null \
      | awk -F'"' '/node.nick|node.description/ { print $2; exit }' \
      | cut -c1-18
    ;;
  mic-muted)
    wpctl get-volume "$SRC" | grep -q MUTED && echo true || echo false
    ;;
  mic-toggle)
    wpctl set-mute "$SRC" toggle
    ;;
  *)
    echo "usage: volume.sh {get|muted|set <n>|toggle|sink|mic-muted|mic-toggle}" >&2
    exit 1
    ;;
esac

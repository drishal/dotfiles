#!/usr/bin/env bash
# Notification indicator for the bar. Reports a waiting/count state and toggles
# history. Supports dunst and mako; on DankMaterialShell (no CLI source) it
# stays a neutral bell you can rewire. Output: JSON {count, dnd}.
set -euo pipefail

case "${1:-status}" in
  toggle)
    if command -v dunstctl >/dev/null 2>&1; then
      dunstctl history-pop >/dev/null 2>&1 || true
    elif command -v makoctl >/dev/null 2>&1; then
      makoctl restore >/dev/null 2>&1 || true
    fi
    exit 0
    ;;
  dnd)
    # toggle do-not-disturb where supported
    if command -v dunstctl >/dev/null 2>&1; then
      cur=$(dunstctl is-paused 2>/dev/null || echo false)
      [ "$cur" = "true" ] && dunstctl set-paused false || dunstctl set-paused true
    fi
    exit 0
    ;;
esac

count=0
dnd=false
if command -v dunstctl >/dev/null 2>&1; then
  count=$(dunstctl count waiting 2>/dev/null || echo 0)
  dnd=$(dunstctl is-paused 2>/dev/null || echo false)
elif command -v makoctl >/dev/null 2>&1; then
  count=$(makoctl list 2>/dev/null | grep -c 'id' || echo 0)
fi

printf '{"count":%d,"dnd":%s}\n' "${count:-0}" "$dnd"

#!/usr/bin/env bash
# Screen brightness via brightnessctl. On a desktop with no backlight this
# gracefully reports 100 and ignores sets.
set -euo pipefail

if ! command -v brightnessctl >/dev/null 2>&1 || [ -z "$(brightnessctl -l 2>/dev/null | grep backlight || true)" ]; then
  case "${1:-get}" in
    get) echo 100 ;;
    *)   : ;;       # no backlight: nothing to set
  esac
  exit 0
fi

case "${1:-get}" in
  get) brightnessctl -m | awk -F, '{ gsub("%","",$4); print $4 }' ;;
  set) brightnessctl set "${2:-100}%" -q ;;
  *)   echo "usage: brightness.sh {get|set <n>}" >&2; exit 1 ;;
esac

#!/usr/bin/env bash
# Move the calendar month: prev / next / reset. Writes the new offset and pokes
# cal-stream.sh (SIGUSR1) to re-emit.
set -uo pipefail
offfile="${XDG_CACHE_HOME:-$HOME/.cache}/eww/caloffset"
mkdir -p "$(dirname "$offfile")"
cur=$(cat "$offfile" 2>/dev/null || echo 0)
case "${1:-reset}" in
  prev) cur=$((cur - 1)) ;;
  next) cur=$((cur + 1)) ;;
  *)    cur=0 ;;
esac
echo "$cur" >"$offfile"
pkill -USR1 -f cal-stream.sh 2>/dev/null || true

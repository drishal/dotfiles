#!/usr/bin/env bash
# Night-light toggle. Tries gammastep/wlsunset if present; otherwise a no-op so
# the button still flips its visual state. Wire to your preference later.
set -euo pipefail

on=${1:-false}

if command -v gammastep >/dev/null 2>&1; then
  if [ "$on" = "true" ]; then
    pgrep -x gammastep >/dev/null || gammastep -O 4000 >/dev/null 2>&1 &
  else
    pkill -x gammastep 2>/dev/null || true
  fi
elif command -v wlsunset >/dev/null 2>&1; then
  if [ "$on" = "true" ]; then
    pgrep -x wlsunset >/dev/null || wlsunset -T 4001 -t 4000 >/dev/null 2>&1 &
  else
    pkill -x wlsunset 2>/dev/null || true
  fi
fi
exit 0

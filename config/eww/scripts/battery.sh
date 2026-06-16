#!/usr/bin/env bash
# Battery state as JSON for the bar. Reports present:false on desktops so the
# widget hides itself. The icon field is filled in by the yuck (glyph ramp).
set -euo pipefail

bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1 || true)
if [ -z "$bat" ]; then
  echo '{"present":false,"perc":0,"status":"NA","charging":false}'
  exit 0
fi

perc=$(cat "$bat/capacity" 2>/dev/null || echo 0)
status=$(cat "$bat/status" 2>/dev/null || echo Unknown)
charging=false
[ "$status" = "Charging" ] && charging=true

printf '{"present":true,"perc":%d,"status":"%s","charging":%s}\n' \
  "$perc" "$status" "$charging"

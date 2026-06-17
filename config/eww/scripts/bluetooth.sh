#!/usr/bin/env bash
# Bluetooth status as JSON, or toggle the controller power. Uses bluetoothctl.
#
# Every bluetoothctl call is wrapped in `timeout`: bluetoothctl can block
# indefinitely on a busy/unresponsive D-Bus, and since eww polls this on a
# timer, a hung call lets copies stack up forever (process + thread leak).
set -euo pipefail

# bluetoothctl can hang on D-Bus; never let a call run longer than this.
bt() { timeout 3 bluetoothctl "$@" 2>/dev/null; }

if ! command -v bluetoothctl >/dev/null 2>&1; then
  echo '{"on":false,"label":"No adapter"}'
  exit 0
fi

if [ "${1:-status}" = "toggle" ]; then
  if bt show | grep -q "Powered: yes"; then
    bt power off >/dev/null || true
  else
    bt power on  >/dev/null || true
  fi
  exit 0
fi

show=$(bt show || true)
if [ -z "$show" ]; then
  echo '{"on":false,"label":"No adapter"}'
  exit 0
fi

if ! grep -q "Powered: yes" <<<"$show"; then
  echo '{"on":false,"label":"Off"}'
  exit 0
fi

# Name of the first connected device, else "On".
dev=$(bt devices Connected | head -1 | cut -d' ' -f3- | cut -c1-18)
label=${dev:-On}
printf '{"on":true,"label":"%s"}\n' "$label"

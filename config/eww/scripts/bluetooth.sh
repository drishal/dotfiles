#!/usr/bin/env bash
# Bluetooth status as JSON, or toggle the controller power. Uses bluetoothctl.
set -euo pipefail

if ! command -v bluetoothctl >/dev/null 2>&1; then
  echo '{"on":false,"label":"No adapter"}'
  exit 0
fi

if [ "${1:-status}" = "toggle" ]; then
  if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    bluetoothctl power off >/dev/null 2>&1 || true
  else
    bluetoothctl power on  >/dev/null 2>&1 || true
  fi
  exit 0
fi

show=$(bluetoothctl show 2>/dev/null || true)
if [ -z "$show" ]; then
  echo '{"on":false,"label":"No adapter"}'
  exit 0
fi

if ! grep -q "Powered: yes" <<<"$show"; then
  echo '{"on":false,"label":"Off"}'
  exit 0
fi

# Name of the first connected device, else "On".
dev=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3- | cut -c1-18)
label=${dev:-On}
printf '{"on":true,"label":"%s"}\n' "$label"

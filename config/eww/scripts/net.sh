#!/usr/bin/env bash
# Network status as JSON, or open a connection menu. Uses NetworkManager.
set -euo pipefail

if [ "${1:-status}" = "menu" ]; then
  # Prefer a graphical editor; fall back to the TUI in a terminal.
  if command -v nm-connection-editor >/dev/null 2>&1; then
    nm-connection-editor &
  else
    "${TERMINAL:-kitty}" -e nmtui &
  fi
  exit 0
fi

if ! command -v nmcli >/dev/null 2>&1; then
  echo '{"up":false,"label":"No NM","type":"none"}'
  exit 0
fi

# Active primary connection (first non-loopback in the connectivity list).
# DEVICE:TYPE:STATE:CONNECTION — e.g. "eno0:ethernet:connected:Wired connection 1"
line=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null \
  | awk -F: '$3=="connected" && $2!="loopback" {print; exit}')

if [ -z "$line" ]; then
  echo '{"up":false,"label":"Disconnected","type":"none"}'
  exit 0
fi

device=$(printf '%s' "$line" | cut -d: -f1)
type=$(printf '%s' "$line" | cut -d: -f2)
conn=$(printf '%s' "$line" | cut -d: -f4-)

case "$type" in
  wifi)
    # SSID of the active wifi connection (falls back to the profile name).
    ssid=$(nmcli -t -f active,ssid device wifi 2>/dev/null \
      | awk -F: '$1=="yes" {print $2; exit}')
    label=${ssid:-$conn}
    ;;
  *)
    # Ethernet (and anything else): show the interface name, e.g. eno0.
    label=$device
    ;;
esac

label=$(printf '%s' "$label" | cut -c1-20)
printf '{"up":true,"label":"%s","type":"%s","device":"%s"}\n' "$label" "$type" "$device"

#!/usr/bin/env bash
# Rofi power menu. Plain -dmenu so it inherits your rofi theme.
set -euo pipefail

options="\
 Lock
 Suspend
 Logout
 Reboot
 Shutdown"

choice=$(printf '%s\n' "$options" \
  | rofi -dmenu -i -p "Power" -theme-str 'window {width: 220px;}' 2>/dev/null) || exit 0

case "$choice" in
  *Lock)     loginctl lock-session ;;
  *Suspend)  systemctl suspend ;;
  *Logout)   hyprctl dispatch exit ;;
  *Reboot)   systemctl reboot ;;
  *Shutdown) systemctl poweroff ;;
esac

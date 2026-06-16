#!/usr/bin/env bash
# Emit CPU / RAM / disk usage as JSON for eww to poll.
set -euo pipefail

# CPU: delta of busy vs total jiffies over a short window.
read -r _ a b c d _ < /proc/stat
idle1=$d; total1=$((a + b + c + d))
sleep 0.4
read -r _ a b c d _ < /proc/stat
idle2=$d; total2=$((a + b + c + d))
dtotal=$((total2 - total1)); didle=$((idle2 - idle1))
cpu=0
[ "$dtotal" -gt 0 ] && cpu=$(( (100 * (dtotal - didle)) / dtotal ))

# RAM: percent used + human-readable used/total (free -h style) for the bar.
read -r mem memused memtot < <(awk '
  /MemTotal/{t=$2} /MemAvailable/{a=$2}
  END{ printf "%d %.1fG %.0fG\n", (t-a)*100/t, (t-a)/1048576, t/1048576 }' /proc/meminfo)

# Disk: root filesystem usage.
disk=$(df --output=pcent / | tail -1 | tr -dc '0-9')

printf '{"cpu":%d,"mem":%d,"disk":%d,"memused":"%s","memtot":"%s"}\n' \
  "$cpu" "$mem" "${disk:-0}" "$memused" "$memtot"

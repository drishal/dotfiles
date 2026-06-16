#!/usr/bin/env bash
# Stream now-playing metadata as JSON. `deflisten` keeps this running and reads
# a new line on every track / status change via `playerctl --follow`.
set -euo pipefail

empty='{"status":"Stopped","title":"","artist":""}'

if ! command -v playerctl >/dev/null 2>&1; then
  echo "$empty"
  exit 0
fi

emit() {
  # Escape the few characters that would break the JSON string.
  esc() { sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' <<<"$1"; }
  printf '{"status":"%s","title":"%s","artist":"%s"}\n' \
    "$(esc "${1:-Stopped}")" "$(esc "${2:-}")" "$(esc "${3:-}")"
}

# Print current state once on startup so the widget is never blank…
status=$(playerctl status 2>/dev/null || echo Stopped)
if [ "$status" != "Stopped" ] && [ -n "$status" ]; then
  emit "$status" "$(playerctl metadata title 2>/dev/null || true)" \
                 "$(playerctl metadata artist 2>/dev/null || true)"
else
  echo "$empty"
fi

# …then follow changes. The format keeps fields tab-separated for easy split.
playerctl --follow metadata --format $'{{status}}\t{{title}}\t{{artist}}' 2>/dev/null \
  | while IFS=$'\t' read -r st ti ar; do
      [ -z "$st" ] && { echo "$empty"; continue; }
      emit "$st" "$ti" "$ar"
    done

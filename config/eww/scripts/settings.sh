#!/usr/bin/env bash
# Open a settings surface. Placeholder — point this at whatever you prefer
# (nm-connection-editor, pavucontrol, a DMS pane, …).
set -euo pipefail

for app in pavucontrol nm-connection-editor blueman-manager; do
  if command -v "$app" >/dev/null 2>&1; then exec "$app"; fi
done
exit 0

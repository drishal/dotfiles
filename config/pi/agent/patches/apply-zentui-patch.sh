#!/usr/bin/env bash
# Re-apply the pi-zentui token-context patch (real token counts instead of
# percentages in the footer/editor context readout) after updating pi-zentui.
#
# Usage:
#   apply-zentui-patch.sh            check state, apply if needed
#   apply-zentui-patch.sh --check    status only, no changes
set -uo pipefail
PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/npm/node_modules/pi-zentui"
PATCH_FILE="$PATCH_DIR/pi-zentui-token-context.patch"

[ -d "$PKG_DIR" ] || { echo "pi-zentui not found at $PKG_DIR" >&2; exit 1; }
VER="$(node -p "require('$PKG_DIR/package.json').version" 2>/dev/null || echo unknown)"
echo "pi-zentui version: $VER"

cd "$PKG_DIR" || exit 1

if patch -p1 --dry-run -R -N < "$PATCH_FILE" >/dev/null 2>&1; then
  echo "Status: patch already applied."
  [ "${1:-}" = "--check" ] && exit 0
  exit 0
fi

if patch -p1 --dry-run -N < "$PATCH_FILE" >/dev/null 2>&1; then
  echo "Status: patch not applied."
  [ "${1:-}" = "--check" ] && exit 0
  if patch -p1 -N < "$PATCH_FILE"; then
    echo "OK: patch applied."
    exit 0
  fi
  echo "Failed: patch errored while applying." >&2
  exit 1
fi

echo "Status: CONFLICT - patch does not apply cleanly to this version." >&2
echo "Upstream likely changed these files. Review manually:" >&2
echo "  git-format:  cd $PKG_DIR && git apply --check $PATCH_FILE" >&2
echo "Then regenerate the patch from a clean upstream copy:" >&2
echo "  diff -ru <clean>/extensions <patched>/extensions > $PATCH_FILE" >&2
exit 2

#!/usr/bin/env bash
# Airplane-mode tile backend. `get` prints true when every radio is soft-blocked,
# `toggle` flips all radios. A udev ACL grants drishal rw on /dev/rfkill, so no
# sudo is needed (see `getfacl /dev/rfkill`). The SOFT column reads
# "blocked"/"unblocked", so match the whole word to avoid the substring trap.
set -uo pipefail

soft() { rfkill --output SOFT --noheadings 2>/dev/null; }

case "${1:-get}" in
  get)
    command -v rfkill >/dev/null 2>&1 || { echo false; exit 0; }
    out=$(soft); [ -z "$out" ] && { echo false; exit 0; }
    if grep -qiw unblocked <<<"$out"; then echo false; else echo true; fi
    ;;
  toggle)
    if soft | grep -qiw unblocked; then rfkill block all; else rfkill unblock all; fi
    ;;
esac

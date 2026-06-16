#!/usr/bin/env bash
#
# cliphist clipboard history in wofi, with image thumbnails.
#
# Image entries from `cliphist list` look like:
#   42	[[ binary data 12 KiB png 320x240 ]]
# wofi can't render those, so we decode each image entry to a temp file and emit
# a wofi `img:<path>:text:<row>` line (rendered as a thumbnail via --allow-images).
# Text rows pass through verbatim. The chosen row is decoded back to the
# clipboard with wl-copy. Requires: cliphist, wl-clipboard, wofi, gawk.
set -euo pipefail

tmp_dir="$(mktemp -d /tmp/cliphist-wofi.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT

# Build the menu: decode image rows to thumbnails, pass everything else through.
menu=$(cliphist list | gawk -v tmp="$tmp_dir" '
  match($0, /^([0-9]+)\t\[\[ binary data .* (jpe?g|png|bmp|webp|gif) /, m) {
    path = tmp "/" m[1] "." m[2]
    if (system("cliphist decode " m[1] " > \"" path "\"") == 0) {
      print "img:" path ":text:" $0
      next
    }
  }
  { print }
')

[ -z "$menu" ] && exit 0

choice=$(printf '%s\n' "$menu" |
  wofi --dmenu --allow-images --parse-search --prompt "clipboard" --width 700 --height 500) || exit 0
[ -z "$choice" ] && exit 0

# Strip the `img:<path>:text:` wrapper we may have added.
selection=$(printf '%s' "$choice" | sed 's/^img:[^:]*:text://')

# For image entries, re-copy with an explicit image MIME type so CLI tools that
# read the clipboard (e.g. `claude` via wl-paste --type image/png) recognise it.
# wl-copy can infer png, but being explicit keeps jpeg/webp/gif robust too.
img_type=$(printf '%s' "$selection" |
  grep -oE 'binary data .*(jpe?g|png|bmp|webp|gif)' | grep -oE '(jpe?g|png|bmp|webp|gif)$')
case "$img_type" in
  jpg | jpeg) printf '%s' "$selection" | cliphist decode | wl-copy --type image/jpeg ;;
  png | bmp | webp | gif) printf '%s' "$selection" | cliphist decode | wl-copy --type "image/$img_type" ;;
  *) printf '%s' "$selection" | cliphist decode | wl-copy ;;
esac

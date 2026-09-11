#!/usr/bin/env bash
#
# Screen capture for Hyprland.
#
# grimshot resolves the focused output with `swaymsg -t get_outputs`, which has
# no socket under Hyprland: OUTPUT comes back empty and grim silently composites
# every monitor instead. Ask hyprctl, which is always on PATH in a session.
#
# Usage: capture.sh <output | area | window | text>

notify() { notify-send -a capture -t 2000 "$@" 2>/dev/null || true; }

# jq filter: a client object -> a grim -g geometry string, empty if unset.
WINDOW_GEOM='select(.size) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'

case "${1:-output}" in
  output)
    grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" - |
      wl-copy --type image/png
    notify "Copied screen to clipboard"
    ;;
  area)
    geom=$(slurp) || exit 0
    grim -g "$geom" - | wl-copy --type image/png
    notify "Copied selection to clipboard"
    ;;
  window)
    # activewindow is {} while focus sits on a layer surface (bar, launcher),
    # so fall back to the most recently focused client.
    geom=$(hyprctl activewindow -j | jq -r "$WINDOW_GEOM")
    [[ -n $geom ]] || geom=$(hyprctl clients -j |
      jq -r "map(select(.focusHistoryID == 0)) | .[0] | $WINDOW_GEOM")

    [[ -n $geom ]] || { notify "No focused window"; exit 1; }
    grim -g "$geom" - | wl-copy --type image/png
    notify "Copied window to clipboard"
    ;;
  text)
    # Freeze the screen first, so grim captures the frozen overlay rather than
    # content shifting underneath as hyprpicker tears down.
    hyprpicker -r -z >/dev/null 2>&1 &
    picker=$!
    trap 'kill "$picker" 2>/dev/null || true' EXIT
    sleep .1

    geom=$(slurp) || exit 0
    text=$(grim -g "$geom" - |
      tesseract stdin stdout --oem 1 --psm 6 -l "${CAPTURE_OCR_LANGS:-eng}" \
        --dpi 300 -c preserve_interword_spaces=1 2>/dev/null) || true

    [[ -n $text ]] || { notify "No text found in selection"; exit 1; }
    printf '%s' "$text" | wl-copy
    notify "Copied text from selection"
    ;;
  *)
    echo "Usage: capture.sh <output | area | window | text>" >&2
    exit 1
    ;;
esac

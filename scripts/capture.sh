#!/usr/bin/env bash
#
# Screen capture for Hyprland.
#
# grimshot resolves the focused output with `swaymsg -t get_outputs`, which has
# no socket under Hyprland: OUTPUT comes back empty and grim silently composites
# every monitor instead. Ask hyprctl, which is always on PATH in a session.
#
# Usage: capture.sh <output | area | window>

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
  *)
    echo "Usage: capture.sh <output | area | window>" >&2
    exit 1
    ;;
esac

agent="${1:-}"
requested_status="${2:-}"

case "$agent" in
  claude|codex|hermes|opencode) ;;
  *) exit 0 ;;
esac

case "$requested_status" in
  working|done|ask) ;;
  *) exit 0 ;;
esac

[ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ] || exit 0

status_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-agent-status"
pane_dir="$status_dir/panes"
refresh_file="$status_dir/.sidebar-refresh"
session="$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}' 2>/dev/null)" || exit 0
[ -n "$session" ] || exit 0

mkdir -p "$pane_dir"
printf '%s\n' "$agent" > "$pane_dir/${session}_${TMUX_PANE}.agent"
printf '%s\n' "$requested_status" > "$pane_dir/${session}_${TMUX_PANE}.status"

session_status="done"
for pane_status_file in "$pane_dir/${session}_"*.status; do
  [ -f "$pane_status_file" ] || continue
  pane_status="$(<"$pane_status_file")"
  case "$pane_status" in
    working)
      session_status="working"
      break
      ;;
    ask)
      [ "$session_status" = "working" ] || session_status="ask"
      ;;
    wait)
      case "$session_status" in
        working|ask) ;;
        *) session_status="wait" ;;
      esac
      ;;
  esac
done

printf '%s\n' "$session_status" > "$status_dir/${session}.status"
touch "$refresh_file"

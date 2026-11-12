#!/bin/sh
# Keeps this pane attached to the Herdr terminal named in the target file.
# The target is "MACHINE TERMINAL_ID" (MACHINE is "local" or an ssh target). The plugin writes a
# new target and sends ctrl+b q; the attach ends and the loop picks up the new one.
#   follow.sh TARGET_FILE [LOCAL_HERDR_BIN]

file="$1"
local_herdr="${2:-herdr}"
on="$file.on" # the target this pane is attached to right now, empty while waiting

: > "$on"
waiting=""
failures=0
while :; do
	target=$(cat "$file" 2>/dev/null)
	if [ -z "$target" ] || [ "$target" = "$waiting" ]; then
		sleep 0.3
		continue
	fi
	waiting=""
	machine=${target% *}
	terminal=${target##* }
	[ "$machine" = "$target" ] && machine=local
	printf '%s' "$target" > "$on"
	if [ "$machine" = local ]; then
		"$local_herdr" terminal attach "$terminal"
	else
		ssh -t -o ConnectTimeout=8 "$machine" herdr terminal attach "$terminal"
	fi
	status=$?
	: > "$on"
	[ "$(cat "$file" 2>/dev/null)" = "$target" ] || { failures=0; continue; }
	if [ "$status" -ne 0 ] && [ "$failures" -lt 5 ]; then
		# A pane that isn't laid out yet has no size and Herdr refuses it; try again shortly.
		failures=$((failures + 1))
		sleep 1
		continue
	fi
	# Same target: the user detached, or attaching keeps failing. Wait for a new one.
	failures=0
	waiting="$target"
	printf '\033[2J\033[H'
	if [ "$status" -ne 0 ]; then
		printf 'Attaching to %s on %s failed (exit %s).\n' "$terminal" "$machine" "$status"
	fi
	printf 'Detached. Pick a pane in the Herdr sidebar, or close this block.\n'
done

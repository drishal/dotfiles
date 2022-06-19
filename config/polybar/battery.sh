
#!/bin/sh
case $BLOCK_BUTTON in
	3) notify-send "🔋 Battery module" "🔋: discharging
🛑: not charging
♻: stagnant charge
 : charging
 : charged
 : battery very low!
- Scroll to change adjust xbacklight." ;;
	4) xbacklight -inc 10 ;;
	5) xbacklight -dec 10 ;;
	6) "$TERMINAL" -e "$EDITOR" "$0" ;;
esac

# Loop through all attached batteries and format the info
for battery in /sys/class/power_supply/BAT?*; do
	# If non-first battery, print a space separator.
	[ -n "${capacity+x}" ] && printf " "
	# Sets up the status and capacity
	case "$(cat "$battery/status" 2>&1)" in
		"Full") status=" " ;;
		"Discharging") status=" " ;;
		"Charging") status=" " ;;
		"Not charging") status="🛑 " ;;
		"Unknown") status="♻ " ;;
		*) exit 1 ;;
	esac
	capacity="$(cat "$battery/capacity" 2>&1)"
	# Will make a warn variable if discharging and low
	[ "$status" = " " ] && [ "$capacity" -le 25 ] && warn=" "
	# Prints the info
	printf  "BAT: %s%s%s%% " "$status" "$warn" "$capacity " ; unset warn
done && printf "\\n"
# battery=$(acpi | awk '{print $4 " | "$5" "}' | sed s/,//g | rev | cut -c 5- | rev ) 
#echo "^c$green^ $battery"

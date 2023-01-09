#!/usr/bin/env bash
#
# wayar-dwl.sh - display dwl tags, layout, and active title
#   Based heavily upon this script by user "novakane" (Hugo Machet) used to do the same for yambar
#   https://codeberg.org/novakane/yambar/src/branch/master/examples/scripts/dwl-tags.sh
#
# USAGE: waybar-dwl.sh MONITOR COMPONENT
#        "MONITOR"   is a wayland output such as "eDP-1"
#        "COMPONENT" is an integer representing a dwl tag OR "layout" OR "title"
#
# REQUIREMENTS:
#  - inotifywait ( 'inotify-tools' on arch )
#  - Launch dwl with `dwl > ~.cache/dwltags` or change $fname
#
# Now the fun part
#
### Example ~/.config/waybar/config
#
# {
#   "modules-left": ["custom/dwl_tag#0", "custom/dwl_tag#1", "custom/dwl_tag#2", "custom/dwl_tag#3", "custom/dwl_tag#4", "custom/dwl_tag#5", "custom/dwl_layout", "custom/dwl_title"],
#   // The empty '' argument used in the following "exec": fields works for single-monitor setups
#   // For multi-monitor setups, see https://github.com/Alexays/Waybar/wiki/Configuration
#   //     and enter the monitor id (like "eDP-1") as the first argument to waybar-dwl.sh
#   "custom/dwl_tag#0": {
#     "exec": "/path/to/waybar-dwl.sh '' 0",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_tag#1": {
#     "exec": "/path/to/waybar-dwl.sh '' 1",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_tag#2": {
#     "exec": "/path/to/waybar-dwl.sh '' 2",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_tag#3": {
#     "exec": "/path/to/waybar-dwl.sh '' 3",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_tag#4": {
#     "exec": "/path/to/waybar-dwl.sh '' 4",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_tag#5": {
#     "exec": "/path/to/waybar-dwl.sh '' 5",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_tag#6": {
#     "exec": "/path/to/waybar-dwl.sh '' 6",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_tag#7": {
#     "exec": "/path/to/waybar-dwl.sh '' 7",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_tag#8": {
#     "exec": "/path/to/waybar-dwl.sh '' 8",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_tag#9": {
#     "exec": "/path/to/waybar-dwl.sh '' 9",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_layout": {
#     "exec": "/path/to/waybar-dwl.sh '' layout",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_title": {
#     "exec": "/path/to/waybar-dwl.sh '' title",
#     "format": "{}",
#     "escape": true,
#     "return-type": "json"
#   }
# }
#
### Example ~/.config/waybar/style.css
# #custom-dwl_layout {
#     color: #EC5800
# }
#
# #custom-dwl_title {
#     color: #017AFF
# }
#
# #custom-dwl_tag {
#     color: #875F00
# }
#
# #custom-dwl_tag.selected {
#     color: #017AFF
# }
#
# #custom-dwl_tag.urgent {
#     background-color: #FF0000
# }
#
# #custom-dwl_tag.active {
#     border-top: 1px solid #EC5800
# }

# Variables
declare output title layout activetags selectedtags
declare -a tags name
readonly fname="$HOME"/.cache/dwltags

tags=( "1" "2" "3" "4" "5" "6" "7" "8" "9" )
name=( "1" "2" "3" "4" "5" "6" "7" "8" "9" ) # Array of labels for tags

monitor="${1}"
component="${2}"

_cycle() {
    case "${component}" in
	# If you use fewer than 9 tags, reduce this array accordingly
	[012345678])
	    this_tag="${component}"
	    unset this_status
	    mask=$((1<<this_tag))

	    if (( "${activetags}"   & mask )) 2>/dev/null; then this_status+='"active",'  ; fi
	    if (( "${selectedtags}" & mask )) 2>/dev/null; then this_status+='"selected",'; fi
	    if (( "${urgenttags}"   & mask )) 2>/dev/null; then this_status+='"urgent",'  ; fi

	    if [[ "${this_status}" ]]; then
		printf -- '{"text":" %s ","class":[%s]}\n' "${name[this_tag]}" "${this_status}"
	    else
		printf -- '{"text":" %s "}\n' "${name[this_tag]}"
	    fi
	    ;;
	layout)
	    printf -- '{"text":"  %s  "}\n' "${layout}"
	    ;;
	title)
	    printf -- '{"text":"%s"}\n' "${title}"
	    ;;
	*)
	    printf -- '{"text":"INVALID INPUT"}\n'
	    ;;
    esac
}

while [[ -n "$(pgrep waybar)" ]] ; do

    [[ ! -f "${fname}" ]] && printf -- '%s\n' \
				    "You need to redirect dwl stdout to ~/.cache/dwltags" >&2

    # Get info from the file
    output="$(grep  "${monitor}" "${fname}" | tail -n6)"
    title="$(echo   "${output}" | grep '^[[:graph:]]* title'  | cut -d ' ' -f 3-  | sed s/\"/“/g | cut -c -55)" # Replace quotes - prevent waybar crash
    layout="$(echo  "${output}" | grep '^[[:graph:]]* layout' | cut -d ' ' -f 3- )"
    selmon="$(echo "${output}" | grep 'selmon')"

    # Get the tag bit mask as a decimal
    activetags="$(echo "${output}"   | grep '^[[:graph:]]* tags' | awk '{print $3}')"
    selectedtags="$(echo "${output}" | grep '^[[:graph:]]* tags' | awk '{print $4}')"
    urgenttags="$(echo "${output}"   | grep '^[[:graph:]]* tags' | awk '{print $6}')"

    _cycle

    # 60-second timeout keeps this from becoming a zombified process when waybar is no longer running
    inotifywait -t 60 -qq --event modify "${fname}"

done

unset -v activetags layout name output selectedtags tags title


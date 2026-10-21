#!/usr/bin/env bash
# rofi script mode: system commands. Each row carries its action in `info`.
# Follow-up menus (confirm, audio output) and screen grabs re-run this script
# with --after, which waits for the calling rofi to exit: rofi is single-instance,
# and a grab would otherwise capture rofi itself.
set -euo pipefail

self=$0
menu_args=(-dmenu -theme palette -show-icons -i -no-custom -format i)

row() { printf '%s\0icon\x1f%s\x1finfo\x1f%s\x1fmeta\x1f%s\n' "$1" "$2" "$3" "${4:-}"; }
run() { setsid -f "$@" >/dev/null 2>&1 </dev/null; }
after_rofi() { run env -u ROFI_RETV -u ROFI_INFO -u ROFI_DATA "$self" --after "$PPID" "$@"; }

list() {
  row "Lock Screen" system-lock-screen lock
  row "Log Out" system-log-out ask:logout "exit session"
  row "Suspend" system-suspend suspend sleep
  row "Reboot" system-reboot ask:reboot restart
  row "Shut Down" system-shutdown ask:poweroff "power off"

  if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v capture >/dev/null; then
    row "Screenshot Area" accessories-screenshot grab:area "capture region"
    row "Screenshot Window" accessories-screenshot grab:window capture
    row "Screenshot Screen" accessories-screenshot grab:output "capture monitor"
    row "Copy Text from Screen" ocrfeeder grab:text "ocr capture"
  fi
  row "Pick Colour" color-picker pick "eyedropper hex"
  row "Switch Audio Output" audio-speakers sinks "sound speaker headphones sink"

  if nmcli -t -f TYPE device 2>/dev/null | grep -qx wifi; then
    if [[ $(nmcli radio wifi) == enabled ]]; then
      row "Turn Wi-Fi Off" network-wireless wifi:off "wireless network"
    else
      row "Turn Wi-Fi On" network-wireless wifi:on "wireless network"
    fi
  fi
  # bluetoothctl blocks forever without an adapter.
  local bt=""
  local hci
  for hci in /sys/class/bluetooth/hci*; do
    [[ -e $hci ]] && bt=$(timeout 1 bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}' || true)
    break
  done
  if [[ $bt == yes ]]; then
    row "Turn Bluetooth Off" bluetooth bt:off
  elif [[ $bt == no ]]; then
    row "Turn Bluetooth On" bluetooth bt:on
  fi

  local status track
  if status=$(playerctl status 2>/dev/null); then
    track=$(playerctl metadata --format '{{title}}{{ " — " + artist }}' 2>/dev/null || true)
    if [[ $status == Playing ]]; then
      row "Pause  ${track}" media-playback-pause media:play-pause "media music"
    else
      row "Play  ${track}" media-playback-start media:play-pause "media music"
    fi
    row "Next Track" media-skip-forward media:next "media music skip"
    row "Previous Track" media-skip-backward media:previous "media music"
  fi

  row "Empty Trash" user-trash-full ask:trash "delete files"
  row "Clear Clipboard History" edit-clear-history ask:wipe "cliphist"
}

confirm() {
  local what=$1 label
  case $what in
    logout) label="Log out" ;;
    reboot) label="Reboot" ;;
    poweroff) label="Shut down" ;;
    trash) label="Empty the trash" ;;
    wipe) label="Clear clipboard history" ;;
  esac
  local pick
  pick=$(printf '%s\0icon\x1femblem-ok\nCancel\0icon\x1fdialog-cancel\n' "$label" |
    rofi "${menu_args[@]}" -p "Confirm" -mesg "$label?") || return 0
  if [[ $pick == 0 ]]; then act "$what"; fi
}

sinks() {
  local rows ids=() names=() active=0 i=0 id name current pick
  rows=$(pw-dump | jq -r '
    (first(.[] | select(.type == "PipeWire:Interface:Metadata" and .props["metadata.name"] == "default")
      | .metadata[] | select(.key == "default.audio.sink") | .value.name) // "") as $def
    | .[] | select(.info.props["media.class"]? == "Audio/Sink")
    | [.id, (.info.props["node.description"] // .info.props["node.name"]), (.info.props["node.name"] == $def)]
    | @tsv')
  [[ -n $rows ]] || return 0
  while IFS=$'\t' read -r id name current; do
    ids+=("$id")
    names+=("$name")
    [[ $current == true ]] && active=$i
    i=$((i + 1))
  done <<<"$rows"
  pick=$(for name in "${names[@]}"; do printf '%s\0icon\x1faudio-card\n' "$name"; done |
    rofi "${menu_args[@]}" -p "Audio Output" -a "$active" -selected-row "$active") || return 0
  wpctl set-default "${ids[$pick]}"
  notify-send -a "Audio" -i audio-speakers "Audio output" "${names[$pick]}"
}

act() {
  case $1 in
    lock) run loginctl lock-session ;;
    suspend) run systemctl suspend ;;
    reboot) run systemctl reboot ;;
    poweroff) run systemctl poweroff ;;
    logout)
      if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
        run hyprctl dispatch 'hl.dsp.exit()'
      else
        run swaymsg exit
      fi
      ;;
    grab:*)
      sleep 0.2 # let rofi's close animation finish
      capture "${1#grab:}"
      ;;
    pick)
      local colour
      colour=$(hyprpicker -a) || return 0
      if [[ -n $colour ]]; then notify-send -a "Colour" -i color-picker "$colour" "Copied to clipboard"; fi
      ;;
    wifi:*) run nmcli radio wifi "${1#wifi:}" ;;
    bt:*) run bluetoothctl power "${1#bt:}" ;;
    media:*) run playerctl "${1#media:}" ;;
    trash) run gio trash --empty ;;
    wipe) cliphist wipe ;;
    sinks) sinks ;;
    confirm:*) confirm "${1#confirm:}" ;;
  esac
}

if [[ ${1:-} == --after ]]; then
  while kill -0 "$2" 2>/dev/null; do sleep 0.05; done
  act "$3"
  exit 0
fi

case ${ROFI_RETV:-0} in
  1)
    case $ROFI_INFO in
      ask:*) after_rofi "confirm:${ROFI_INFO#ask:}" ;;
      grab:* | pick | sinks) after_rofi "$ROFI_INFO" ;;
      *) act "$ROFI_INFO" ;;
    esac
    ;;
  *) list ;;
esac

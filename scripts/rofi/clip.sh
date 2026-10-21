#!/usr/bin/env bash
# rofi script mode: cliphist history. Images get cached thumbnails as row icons;
# Enter copies, Shift+Delete (kb-delete-entry) removes the row.
set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/rofi-clip"
mkdir -p "$cache"

copy() {
  local id=$1 type=$2
  # wl-copy forks a server; it must not hold rofi's stdout open.
  case $type in
    text) cliphist decode "$id" | wl-copy >/dev/null 2>&1 ;;
    jpg) cliphist decode "$id" | wl-copy --type image/jpeg >/dev/null 2>&1 ;;
    *) cliphist decode "$id" | wl-copy --type "image/$type" >/dev/null 2>&1 ;;
  esac
}

list() {
  printf '\0message\x1fEnter copies · Shift+Del removes\n'
  printf '\0no-custom\x1ftrue\n'
  local keep=" " id preview type icon
  while IFS=$'\t' read -r id preview; do
    keep+="$id "
    if [[ $preview =~ ^\[\[\ binary\ data\ (.*)\ (jpe?g|png|bmp|webp|gif)\ ([0-9]+x[0-9]+)\ \]\]$ ]]; then
      type=${BASH_REMATCH[2]/jpeg/jpg}
      icon="$cache/$id.$type"
      [[ -s $icon ]] || cliphist decode "$id" >"$icon" 2>/dev/null || rm -f "$icon"
      printf 'Image  %s · %s\0icon\x1f%s\x1finfo\x1f%s:%s\x1fmeta\x1fimage picture\n' \
        "${BASH_REMATCH[3]}" "${BASH_REMATCH[1]}" "$icon" "$id" "$type"
    else
      icon=text-x-generic
      [[ $preview =~ ^https?:// ]] && icon=insert-link
      printf '%s\0icon\x1f%s\x1finfo\x1f%s:text\n' "$preview" "$icon" "$id"
    fi
  done < <(cliphist list)

  # Drop thumbnails of entries cliphist has since pruned.
  local f base
  for f in "$cache"/*; do
    [[ -e $f ]] || continue
    base=${f##*/}
    [[ $keep == *" ${base%%.*} "* ]] || rm -f "$f"
  done
}

case ${ROFI_RETV:-0} in
  1) copy "${ROFI_INFO%%:*}" "${ROFI_INFO#*:}" ;;
  3)
    printf '%s\t\n' "${ROFI_INFO%%:*}" | cliphist delete
    printf '\0keep-selection\x1ftrue\n'
    list
    ;;
  *) list ;;
esac

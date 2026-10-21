#!/usr/bin/env bash
# rofi script mode: web search. A typed query that matches no row arrives as a
# custom entry; a leading keyword picks the engine, otherwise the first one.
set -euo pipefail

# keyword|name|icon|query url (the query is appended URI-encoded)
engines=(
  "s|SearXNG|system-search|http://127.0.0.1:48431/search?q="
  "g|Google|google|https://www.google.com/search?q="
  "ddg|DuckDuckGo|duckduckgo|https://duckduckgo.com/?q="
  "gh|GitHub|github|https://github.com/search?type=repositories&q="
  "yt|YouTube|youtube|https://www.youtube.com/results?search_query="
  "np|Nix packages|nix-snowflake|https://search.nixos.org/packages?channel=unstable&query="
  "no|NixOS options|nix-snowflake|https://search.nixos.org/options?channel=unstable&query="
  "hm|Home Manager options|nix-snowflake|https://home-manager-options.extranix.com/?release=master&query="
  "w|Wikipedia|wikipedia|https://en.wikipedia.org/w/index.php?search="
  "aw|Arch Wiki|distributor-logo-archlinux|https://wiki.archlinux.org/index.php?search="
  "r|Reddit|reddit|https://www.reddit.com/search/?q="
)

browse() { setsid -f xdg-open "$1" >/dev/null 2>&1 </dev/null; }

search() {
  local query=$1 entry url=${engines[0]##*|}
  if [[ $query == *" "* ]]; then
    for entry in "${engines[@]}"; do
      if [[ ${query%% *} == "${entry%%|*}" ]]; then
        url=${entry##*|}
        query=${query#* }
        break
      fi
    done
  fi
  browse "$url$(jq -rn --arg q "$query" '$q | @uri')"
}

list() {
  printf '\0message\x1fEnter searches SearXNG · start with a keyword to pick a site · Ctrl+Enter forces a search\n'
  printf '\0markup-rows\x1ftrue\n'
  local entry key name icon url
  for entry in "${engines[@]}"; do
    IFS='|' read -r key name icon url <<<"$entry"
    printf '%s\0display\x1f%s   <span alpha="50%%" size="small">%s</span>\x1ficon\x1f%s\x1finfo\x1f%s\n' \
      "$key $name" "$name" "$key" "$icon" "$url"
  done
}

case ${ROFI_RETV:-0} in
  # A row with no query opens the site itself.
  1)
    host=${ROFI_INFO#*//}
    browse "${ROFI_INFO%%//*}//${host%%/*}"
    ;;
  2) if [[ -n ${1// /} ]]; then search "$1"; fi ;;
  *) list ;;
esac

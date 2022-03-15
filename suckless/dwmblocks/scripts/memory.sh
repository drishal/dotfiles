#!/bin/sh
. /home/drishal/dotfiles/suckless/dwmblocks/scripts/themes/onedark.sh
# printf "^c$magenta^   $(free -h | awk '/^Mem/ { print $3 }' | sed s/i//g)"
printf "^c$magenta^   RAM: $(free -h | awk '/^Mem/ { print $3"/"$2 }' | sed s/i//g)"

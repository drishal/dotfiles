# top -bn 1 | awk '/^%Cpu/ { print int($2 + $4 + $6)" %"}'
. ~/dotfiles/suckless/dwmblocks/scripts/themes/onedark.sh
# echo $(^c$magenta^ top -bn 1 | awk '/^%Cpu/ { print int($2 + $4 + $6)" %"}')
cpu_val=$(grep -o "^[^ ]*" /proc/loadavg)

printf " ^c$cyan^  CPU: $cpu_val %% "
# printf "^c$green^ "

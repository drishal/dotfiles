cpu_val=$(grep -o "^[^ ]*" /proc/loadavg)
printf "  CPU: $cpu_val %%"

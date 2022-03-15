#!/bin/sh

variable="Total_LBAs_Written"
decimal_places="3"
device="$1"

[ -z $1 ] && echo "Specify a drive." && exit;

usage=$(echo "scale=${decimal_places}; $(($(doas smartctl -a ${device} | grep "${variable}" | awk '{ print $10 }') * 512)) / 1024 / 1024 / 1024 / 1024" | bc -l)

echo "${usage} TiB written to '${device}' in total."

#!/usr/bin/env bash

# A dwm_bar function to show the current network connection/SSID, private IP, and public IP using NetworkManager
# Joe Standring <git@joestandring.com>
# GNU GPLv3

# Dependencies: NetworkManager, curl

dwm_networkmanager () {
    CONNAME=$(nmcli -a | grep 'Wired connection' | awk 'NR==1{print $1}' | sed 's/://')
    if [ "$CONNAME" = "" ]; then
        CONNAME=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -c 5-)
    fi


    printf "%s" "$SEP1"
    if [ "$IDENTIFIER" = "unicode" ]; then
        printf "  %s %s" "$CONNAME" 
    else
        printf " %s" "$CONNAME" 
    fi
    printf "%s" #"$SEP2"
}

dwm_networkmanager

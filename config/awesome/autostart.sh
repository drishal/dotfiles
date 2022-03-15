#!/bin/bash
# /usr/lib/notification-daemon-1.0/notification-daemon&
xset r rate  300 50
lxpolkit&
picom --experimental-backends&
# feh --bg-scale ~/dotfiles/wallpapers/darkest_hour.jpg
nm-applet&
xfce4-clipman&
xfce4-power-manager&
emacs --daemon&
blueman-applet&
volumeicon&

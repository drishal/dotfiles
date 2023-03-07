#!/usr/bin/env bash

#deadd notifications
# mkdir -p ~/.config/deadd/
ln -sf ~/dotfiles/config/deadd/ ~/.config/

mkdir -p ~/.config/picom
ln -sf ~/dotfiles/config/picom/picom.conf ~/.config/picom/picom.conf 

#waybar
mkdir -p ~/.config/waybar/
ln -sf ~/dotfiles/config/waybar/waybar-hyprland /home/drishal/.config/waybar/config
ln -sf ~/dotfiles/config/waybar/style.css ~/.config/waybar/style.css 

# alacritty
mkdir -p ~/.config/alacritty/
ln -sf ~/dotfiles/config/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml 

# dunst
mkdir -p ~/.config/dunst
ln -sf ~/dotfiles/config/dunst/dunstrc ~/.config/dunst/dunstrc 

# foot
# ln -sf ~/dotfiles/config/foot/foot.ini ~/.config/foot/foot.ini 

#conky
mkdir -p ~/.config/conky/
ln -sf ~/dotfiles/config/conky/onedark.conkyrc ~/.config/conky/onedark.conkyrc 

# polybar
mkdir -p ~/.config/polybar/
ln -sf ~/dotfiles/config/polybar/config.ini ~/.config/polybar/config.ini

# leftwm
mkdir -p ~/.config/leftwm
mkdir -p ~/.config/leftwm/themes
ln -sf ~/dotfiles/config/leftwm/config.toml /home/drishal/.config/leftwm/config.toml
ln -sf ~/dotfiles/config/leftwm/onedark/ /home/drishal/.config/leftwm/themes/current

#neovim
mkdir -p ~/.config/nvim/
ln -sf ~/dotfiles/config/nvim/pre-init.vim ~/.config/nvim/init.vim

# mpv
ln -sf ~/dotfiles/config/mpv/mpv.conf ~/.config/mpv/mpv.conf


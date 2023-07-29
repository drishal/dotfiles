#!/usr/bin/env bash

#deadd notifications
# mkdir -p ~/.config/deadd/
ln -sf ~/dotfiles/config/deadd/ ~/.config/

mkdir -p ~/.config/picom
ln -sf ~/dotfiles/config/picom/picom.conf ~/.config/picom/picom.conf 

#waybar
mkdir -p ~/.config/waybar/
ln -sf ~/dotfiles/config/waybar/waybar-hyprland /home/drishal/.config/waybar/config
# ln -sf ~/dotfiles/config/waybar/waybar-river /home/drishal/.config/waybar/config
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
# ln -sf ~/dotfiles/config/nvim/pre-init.vim ~/.config/nvim/init.vim

# mpv
ln -sf ~/dotfiles/config/mpv/mpv.conf ~/.config/mpv/mpv.conf


# tangle

#fish config 
mkdir -p ~/.config/fish/
emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "~/dotfiles/config/fish/config.org ")'

#hyprland config
mkdir -p ~/.config/hyprland/
emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "~/dotfiles/config/hyprland/hyprland.org ")'

# xmonad config
mkdir -p ~/.config/xmonad
emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "~/dotfiles/xmonad/README.org")'

#qtile config
mkdir -p ~/.config/qtile/
emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "~/dotfiles/config/qtile/README.org")'

#river config
mkdir -p ~/.config/river/
emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "~/dotfiles/config/river/init.org")'

#zsh config
emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "~/dotfiles/zshrc.org")'

#dwm setup
echo "make install dwm"
cd ~/dotfiles/suckless/dwm-6.4
sudo make clean install
sudo cp ~/dotfiles/suckless/dwm.desktop /usr/share/xsessions
cd ~/dotfiles/suckless/dwmblocks
sudo make clean install

# emacs conifg
# mkdir -p ~/.emacs.d
# emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "~/dotfiles/config/river/init.org")'
# if [ ! -f ~/.emacs.d/custom.el ]; then touch ~/.emacs.d/custom.el; fi
# emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "~/dotfiles/emacs.d-gnu/config.org")'


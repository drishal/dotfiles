# this script can be used to update the dotfiles. Make sure dotfiles repo is present at ~/dotfiles

# qtile
mkdir -p ~/dotfiles/config/qtile/
cp ~/.config/qtile/autostart.sh  ~/dotfiles/config/qtile/
cp ~/.config/qtile/README.org   ~/dotfiles/config/qtile/
cp ~/.config/qtile/config.py  ~/dotfiles/config/qtile/

# sxhkd
mkdir -p ~/dotfiles/config/sxhkd
cp ~/.config/sxhkd/ ~/dotfiles/config/sxhkd

# Xmonad
mkdir -p ~/dotfiles/.xmonad/
cp ~/.xmonad/README.org  ~/dotfiles/.xmonad/
cp ~/.xmonad/xmonad.hs  ~/dotfiles/.xmonad/
cp ~/.xmobarrc  ~/dotfiles/.xmobarrc 

# emacs
cp -r ~/.emacs.d/config.org ~/dotfiles/emacs.d-gnu/ 
# suckless/ stuff
mkdir -p ~/dotfiles/config/suckless/
cp -r ~/.config/suckless/ ~/dotfiles/config

# polybar
cp -r ~/.config/polybar/ ~/dotfiles/config/

#rofi
cp -r ~/.config/rofi/ ~/dotfiles/config/


#updating the git repo
echo "input commit message"
read commit
git add .
git commit -m "$commit"
git push all

{ config, inputs, pkgs, ... }:
{
  #xmonad config
  #home.file."/home/drishal/.xmonad/xmonad.hs".source = ../.xmonad/xmonad.hs;
  #home.file."/home/drishal/.xmobarrc".source = ../.xmobarrc;
  #home.file."/home/drishal/.xmonad/lib".source = ../.xmonad/lib;

  #zsh config
  # home.file."/home/drishal/.zshrc".source = ../.zshrc;
  # xresources path
  xresources.path="~/dotfiles/.Xresources";
  # sleep test
  # home.file."${pkgs.systemd}/lib/systemd/system-sleep/batdistrack".source = ../batdistrack;

  # deadd notifications
  home.file."/home/drishal/.config/deadd".source = ../../config/deadd;

  # rofi
  home.file."/home/drishal/.config/rofi/config.rasi".source = ../../config/rofi/config.rasi;

  # home.file."/home/drishal/.config/ro../../config".source = ../config/rofi/config;

  # setting Xresources
  # home.file."/home/drishal/.Xresources".source = ../.Xresources;

  # kitty
  home.file."/home/drishal/.config/kitty".source = ../../config/kitty;

  # picom config
  home.file."/home/drishal/.config/picom/picom.conf".source = ../../config/picom/picom.conf;

  # river
  # home.file."/home/drishal/.config/river".source = ../../config/river;

  #waybar
  # home.file."/home/drishal/.config/waybar/config".source = ../../config/waybar/waybar-hyprland;
  home.file."/home/drishal/.config/waybar/config".source = ../../config/waybar/waybar-dwl;
  # home.file."/home/drishal/.config/waybar/config".source = ../../config/waybar/waybar-river;
  home.file."/home/drishal/.config/waybar/style.css".source = ../../config/waybar/style.css;

  # alacritty
  home.file."/home/drishal/.config/alacritty/alacritty.yml".source = ../../config/alacritty/alacritty.yml;

  # dunst
  home.file."/home/drishal/.config/dunst/dunstrc".source = ../../config/dunst/dunstrc;

  # conky
  home.file."/home/drishal/.config/conky/onedark.conkyrc".source = ../../config/conky/onedark.conkyrc;

  #polybar
  home.file."/home/drishal/.config/polybar/config.ini".source = ../../config/polybar/config.ini;

  # leftwm
  home.file."/home/drishal/.config/leftwm/config.toml".source = ../../config/leftwm/config.toml;
  home.file."/home/drishal/.config/leftwm/themes/current".source = ../../config/leftwm/onedark;

  # awesomewm
  # home.file."/home/drishal/.config/awesome/rc.lua".source = ../../config/awesome/rc.lua;

  # mpv
  home.file."/home/drishal/.config/mpv/mpv.conf".source = ../../config/mpv/mpv.conf;

  #nvim
  # home.file."/home/drishal/.config/nvim/init.vim".source = ../../config/nvim/pre-init.vim;
  # qtile config
  #home.file."/home/drishal/.config/qti../../config.py".source =../config/qtile/config.py;
  # home.file."/home/drishal/.config/qtile/autostart.sh".source =../../config/qtile/autostart.sh;
}

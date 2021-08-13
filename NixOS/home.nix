{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "drishal";
  home.homeDirectory = "/home/drishal";
  programs.rofi = {
    enable = true;
    theme = "${pkgs.rofi}/share/rofi/themes/Arc-Dark.rasi";
  };

  # neovim
  programs.neovim = {
    enable = true;
  };

  # git 
  programs.git = {
  enable = true;
  userName = "drishal";
  userEmail = "drishalballaney@gmail.com";
  }; 

  #.profile
  home.file."/home/drishal/.profile".source =/home/drishal/dotfiles/.profile;

  # xmonad config 
  # home.file."/home/drishal/.xmonad/xmonad.hs".source =/home/drishal/dotfiles/.xmonad/xmonad.hs;

  # qtile config
  # home.file."/home/drishal/config/qtile/config.py".source =/home/drishal/dotfiles/.config/qtile/config.py;
  # home.file."/home/drishal/config/qtile/autostart.sh".source =/home/drishal/dotfiles/.config/qtile/autostart.sh;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  # home.stateVersion = "21.05";
}

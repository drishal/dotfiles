{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = "drishal";
    homeDirectory = "/home/drishal";
    # language.base = "en_US.UTF-8";
    # sessionVariables.LOCALES_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    # sessionVariables.LOCALES_ARCHIVE = "/usr/lib/locale/locale-archive";
  };
  # main programs
  programs = { 
    # rofi
    # rofi = {
    #   enable = false;
    #   theme = "${pkgs.rofi}/share/rofi/themes/Arc-Dark.rasi";
    # };
    # neovim
    # neovim = {
    #   enable = true;
    # };

    # git 
    git = {
      enable = true;
      userName = "drishal";
      userEmail = "drishalballaney@gmail.com";
    }; 

    #Gccemacs
    # emacs = {
    #   enable = true;
    #   package = pkgs.emacsPgtkGcc;
    #   extraPackages = (epkgs: [ epkgs.vterm ] );
    # };
  }; 

  # services
  # services = {
  #   emacs = {
  #     enable = true;
  #     client.enable =true;
  #     socketActivation.enable = true;
  #   };
  #};

  # cachix
  # caches.cachix = [
  #   "emacsPgtkGcc"
  #"someOtherCachix"
  #{ name = "someCachixWithSha"; sha256 = "..."; }
  # ];
  #.profile
  #home.file."/home/drishal/.profile".source=../.profile;

  # xresources = {
  #   path = "/home/drishal/dotfiles/.Xresources";
  # };

  # xmonad config 
  # home.file."/home/drishal/.xmonad/xmonad.hs".source = ../.xmonad/xmonad.hs;
  #home.file."/home/drishal/.xmobarrc".source = ../.xmobarrc;
  #home.file."/home/drishal/.xmonad/lib".source = ../.xmonad/lib;

  # zsh config
  # home.file."/home/drishal/.zshrc".source = ../.zshrc;

  # sleep test
  # home.file."${pkgs.systemd}/lib/systemd/system-sleep/batdistrack".source = ../batdistrack;

  # deadd notifications
  home.file."/home/drishal/.config/deadd".source = ../config/deadd;

  # rofi
  home.file."/home/drishal/.config/rofi/config.rasi".source = ../config/rofi/config.rasi;
  home.file."/home/drishal/.config/rofi/config".source = ../config/rofi/config;
  
  # setting Xresources
  home.file."/home/drishal/.Xresources".source = ../.Xresources;

  # kitty
  home.file."/home/drishal/.config/kitty".source = ../config/kitty;

  # picom config
  home.file."/home/drishal/.config/picom".source = ../config/picom;

  # river
  home.file."/home/drishal/.config/river".source = ../config/river;

  #waybar
  home.file."/home/drishal/.config/waybar".source = ../config/waybar;
  
  
  # qtile config
  home.file."/home/drishal/.config/qtile/config.py".source =../config/qtile/config.py;
  home.file."/home/drishal/.config/qtile/autostart.sh".source =../config/qtile/autostart.sh;

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
{ config, inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    # # firefox
    # chromium
    # comic-mono
    # distrobox
    # exa
    # firefox
    # fish
    # neovide
    # vivaldi-ffmpeg-codecs
    # vivaldi-widevine
    bat
    cachix
    fd
    fzf
    ispell
    glibcLocales
    man
    man-pages
    neofetch
    #rnix
    # sl
    starship
    # neovide
    nixpkgs-fmt
    papirus-icon-theme
    gnome.gnome-themes-extra
    #nodePackages.create-react-app
    #nodePackages.eslint
    #nodePackages.js-beautify
    #nodePackages.pyright
    #nodePackages.react-tools
    # nodePackages.typescript
    # nodePackages.typescript-language-server
    #nodePackages.javascript-typescript-langserver
    # nodePackages.vscode-html-languageserver-bin
    #rofi-emoji
    #rust-analyzer
    #sumneko-lua-language-server 
    #tdlib
    # (pkgs.nerdfonts.override {
    #   fonts = [ "FiraCode"   "Monofur" ];
    # })
  ];

  # direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };


  #lsd
  programs.lsd = {
    enable = true;
    settings = {
      icons = {
        theme = "fancy";
        separator = "  ";
      };
    };
  };


  gtk = {
    enable = true;
    # theme.name = "Orchis-Dark";
    theme.name = "Adwaita-dark";
    iconTheme = with pkgs; {
      name = "Papirus-Dark";
      package = papirus-icon-theme;
    };
    font.name = "Noto Sans 10";
    cursorTheme.name = "breeze_cursors";
    gtk2.extraConfig = ''
      gtk-button-images=1
      gtk-menu-images=1
    '';
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-button-images = 1;
      gtk-cursor-theme-name = "breeze_cursors";
      gtk-cursor-theme-size = 24;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-animations = true;
      # gtk-font-name="Noto Sans, 10";
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-menu-images = 1;
      gtk-modules = "colorreload-gtk-module";
      gtk-primary-button-warps-slider = false;
      # gtk-theme-name="Orchis-Dark";
      # gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ;
      # gtk-xft-dpi=98304;
      # gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR;
      gtk-enable-event-sounds = 1;
      gtk-enable-input-feedback-sounds = 1;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintmedium";
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-cursor-theme-name = "breeze_cursors";
      gtk-cursor-theme-size = 24;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-animations = true;
      # gtk-font-name="Noto Sans 10";
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-modules = "colorreload-gtk-module";
      gtk-primary-button-warps-slider = "false";
      # gtk-theme-name="Orchis-Dark";
      # gtk-xft-dpi=98304;
    };
  };

  # home.pointerCursor = {
  #   name = "breeze_cursors";
  #   # package = pkgs.gnome.adwaita-icon-theme;
  #   package = pkgs.libsForQt5.breeze-qt5;
  #   size = 24;
  #   gtk.enable = true;
  #   x11 = {
  #     enable = true;
  #     # defaultCursor = "Adwaita";
  #   };
  # };

  # swaylock
  # programs.swaylock={
  #   # enable=true;
  #   settings={
  #     # image="~/dotfiles/wallpapers/NixOS-1.png";
  #     image="~/dotfiles/wallpapers/archlinux/archlinux-onedark.png";
  #   };
  # };
  # # caches.cachix = [
  #   {
  #     name = "nix-community";
  #     sha256 = "00lpx4znr4dd0cc4w4q8fl97bdp7q19z1d3p50hcfxy26jz5g21g";
  #   }
  # ];
}

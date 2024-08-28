{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.ags.homeManagerModules.default ];
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
    cowsay
    # inputs.eww.packages.${pkgs.stdenv.hostPlatform.system}.eww
    emacs-lsp-booster
    fd
    fzf
    ispell
    glibcLocales
    man
    man-pages
    neofetch
    # nvchad
    #rnix
    # sl
    starship
    # neovide
    # nixpkgs-fmt
    nixfmt-rfc-style
    nil
    taplo
    # papirus-icon-theme
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

  # ags
#  programs.ags = {
#    enable = true;
#    configDir = null;
#    extraPackages = with pkgs; [
#      gtksourceview
#      webkitgtk
#      accountsservice
#    ];
#  };
#  home.file."${config.home.homeDirectory}/.config/ags/" = {
#    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/ags/";
#    recursive = true;
#  };
#  home.file."${config.home.homeDirectory}/.config/css/ags-color.css".text = with config.scheme;  ''
#      @define-color colbg        #${base00}; 
#      @define-color colbg2       #${base02};
#      @define-color colfg        #${base05};
#      @define-color colgrey      #${base03};
#      @define-color colcyan      #${base0C};
#      @define-color colgreen     #${base0B};
#      @define-color colorange    #${base09};
#      @define-color colmagenta   #${base0E};
#      @define-color colviolet    #${base0F};
#      @define-color colred       #${base08};
#      @define-color colyellow    #${base0A};
#  '';
#
  # xdg.configFile."ags".source = ../../config/ags;
  # home.file."${config.home.homeDirectory}/.config/ags".recursive = true;

  # home.file."/home/drishal/.config/ags".source = ../../config/ags;
  # ".config/ags".source = config.lib.file.mkOutOfStoreSymlink "../../config/ags";
  # xdg.configFile."ags".recursive = true;
  # eww
  # programs.eww = {
  #   enable = true;
  #   package = inputs.eww.packages.${pkgs.stdenv.hostPlatform.system}.eww;
  #   configDir = ../../config/eww/eww-bar;
  # };
  # xdg.configFile."eww/color.css".text = with config.scheme; ''
  #     @define-color colbg        #${base00}; 
  #     @define-color colbg2       #${base02};
  #     @define-color colfg        #${base05};
  #     @define-color colgrey      #${base03};
  #     @define-color colcyan      #${base0C};
  #     @define-color colgreen     #${base0B};
  #     @define-color colorange    #${base09};
  #     @define-color colmagenta   #${base0E};
  #     @define-color colviolet    #${base0F};
  #     @define-color colred       #${base08};
  #     @define-color colyellow    #${base0A};
  # '';
  # xdg.configFile."eww".recursive = true;
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
    # theme.name = "Adwaita-dark";
    # theme = {
    #   name = "Catppuccin-Mocha-Compact-Pink-Dark";
    #   package = pkgs.catppuccin-gtk.override {
    #     accents = [ "pink" ];
    #     size = "compact";
    #     tweaks = [ "rimless" ];
    #     variant = "mocha";
    #   };
      # package = pkgs.gruvbox-gtk-theme;
      # name = "Gruvbox";
      # name = "Orchis-Dark";
      # name = "Arc-Dark";
      # package = pkgs.orchis-theme;
    # };
    iconTheme = with pkgs; {
      name = "Papirus-Dark";
      package = papirus-icon-theme;
    };
    # font.name = "Noto Sans 10";
    # cursorTheme.name = "breeze_cursors";
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

  # zellij
  programs.zellij = {
    enable = true;
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

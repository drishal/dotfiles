{ config,inputs ,pkgs, ... }:

{
imports=[
#  ./emacs-override.nix
];

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
    # neovim
    neovim = {
      enable = true;
      package = pkgs.neovim-nightly;
      extraConfig = builtins.readFile ../config/nvim/init-nix.vim;
      plugins = with pkgs.vimPlugins; [
        vim-addon-nix
        vim-plug
        nvim-lspconfig
        nvim-treesitter
        nvim-cmp cmp-buffer cmp-path cmp-treesitter cmp-spell
        dashboard-nvim 
        orgmode onedark-nvim neoformat vim-nix cmp-nvim-lsp
        barbar-nvim nvim-web-devicons 
        vim-airline vim-airline-themes
        nvim-autopairs  neorg
        vim-markdown
    ];
    extraPackages = with pkgs; [ 
    rnix-lsp gcc vimPlugins.packer-nvim
    ripgrep fd nodePackages.pyright];
    };
    #  rofi = {
    #    enable = false;
    #    theme = "${pkgs.rofi}/share/rofi/themes/Arc-Dark.rasi";
    #  };
    # # git
    #  git = {
    #    enable = true;
    #    userName = "drishal";
    #    userEmail = "drishalballaney@gmail.com";
    #  };

    #   emacs = {
    #     enable = true;
    #     # package = pkgs.emacsGit;
    #     # package = pkgs.emacsPgtkGcc.overrideAttrs (oa: {configureFlags = ["--with-pgtk  --enable-link-time-optimization --with-native-compilation"];});
    #     package = pkgs.emacsPgtkGcc;
    #     extraPackages = (epkgs: [ epkgs.vterm ] );
    #   };
  };

home.packages = with pkgs; [
  neofetch man
  distrobox man-pages
  cachix
  # libgccjit
  # (callPackage ./distrobox.nix {})
  ];


  # services
  services = {
  #   emacs = {
  #     enable = true;
  #     client.enable =true;
  #     socketActivation.enable = true;
  #   };
    # dunst = {
    #  enable = true;
    #  iconTheme = pkgs.papirus-icon-theme; 
    # };
  };

  # cachix
  # caches.cachix = [
  #   "emacsPgtkGcc"
  #"someOtherCachix"
  #{ name = "someCachixWithSha"; sha256 = "..."; }
 
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
  # home.file."/home/drishal/.config/rofi/config.rasi".source = ../config/rofi/config.rasi;
  home.file."/home/drishal/.config/rofi/config".source = ../config/rofi/config;

  # setting Xresources
  home.file."/home/drishal/.Xresources".source = ../.Xresources;

  # kitty
  home.file."/home/drishal/.config/kitty".source = ../config/kitty;

  # picom config
  home.file."/home/drishal/.config/picom/picom.conf".source = ../config/picom/picom.conf;

  # river
  # home.file."/home/drishal/.config/river".source = ../config/river;

  #waybar
  home.file."/home/drishal/.config/waybar".source = ../config/waybar;
  home.file."/home/drishal/.config/waybar/style.css".source = ../config/waybar/style.css;

  # alacritty
  home.file."/home/drishal/.config/alacritty/alacritty.yml".source = ../config/alacritty/alacritty.yml;

  # dunst
  home.file."/home/drishal/.config/dunst/dunstrc".source = ../config/dunst/dunstrc;
  # qtile config
  #home.file."/home/drishal/.config/qtile/config.py".source =../config/qtile/config.py;
  # home.file."/home/drishal/.config/qtile/autostart.sh".source =../config/qtile/autostart.sh;

  #starship

  #home.file."/home/drishal/.config/starship.toml".source =../config/starship.toml;

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

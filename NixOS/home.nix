{ config, inputs, pkgs, ... }:

{
  imports = [
    # ./extra-packages/declarative-cachix/home-manager-cachix.nix
    # ../../.private-stuff/hm-email.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # nix settings...use only for single user installs 
  # nix = {
  #   package = pkgs.nix;
  #   settings = {
  #     experimental-features = [ "nix-command" "flakes" ];
  #   };
  # };
  # # caches.cachix = [
  #   {
  #     name = "nix-community";
  #     sha256 = "00lpx4znr4dd0cc4w4q8fl97bdp7q19z1d3p50hcfxy26jz5g21g";
  #   }
  # ];
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
      # extraConfig =  builtins.readfile ../config/nvim/init-nix.vim;
      extraConfig =
        ''
          ${builtins.readFile ../config/nvim/init.vim }
          lua << EOF
          ${builtins.readFile ../config/nvim/init.lua}
        '';
      plugins = with pkgs.vimPlugins; [
        vim-addon-nix
        nvim-lspconfig
        nvim-cmp
        cmp-buffer
        cmp-path
        cmp-spell
        dashboard-nvim
        (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars))
        cmp-treesitter
        orgmode
        onedark-nvim
        neoformat
        vim-nix
        cmp-nvim-lsp
        barbar-nvim
        nvim-web-devicons
        vim-airline
        vim-airline-themes
        nvim-autopairs
        neorg
        vim-markdown
      ];
      extraPackages = with pkgs; [
        rnix-lsp
        gcc
        vimPlugins.packer-nvim
        ripgrep
        fd
        nodePackages.pyright

      ];
    };

    rofi = {
      enable = false;
      theme = "${pkgs.rofi}/share/rofi/themes/Arc-Dark.rasi";
      # font="FiraCode Nerd Font 14";
      font = "FantasqueSansMono Nerd Font 14";
      plugins = [
        pkgs.rofi-emoji
      ];
    };
    # # git
    git = {
      enable = true;
      userName = "drishal";
      userEmail = "drishalballaney@gmail.com";
      extraConfig = {
        core = {
          editor = "nvim";
          excludesFile = "";
        };
      };
    };
    emacs = {
      enable = false;
      package = pkgs.emacsPgtkNativeComp;
      # package = pkgs.emacs28NativeComp;
      extraPackages = (epkgs: [ epkgs.vterm ]);
    };

    chromium = {
      enable = false;
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--enable-features=WebUIDarkMode"
        "--force-dark-mode"
        "--disable-gpu-driver-bug-workarounds"
        "--enable-features=VaapiVideoDecoder"
        "--oauth2-client-id=77185425430.apps.googleusercontent.com"
        "--oauth2-client-secret=OTJgUOQcT7lO7GsGZq2G4IlT"
      ];
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden 
        { id = "lcbjdhceifofjlpecfpeimnnphbcjgnc"; } #xbrowsersync
      ];
    };
  };

  home.packages = with pkgs; [
    neofetch
    man
    nixpkgs-fmt
    # distrobox
    man-pages
    cachix
    rust-analyzer
    # neovide
    ispell
    # firefox
    # exa
    # chromium
    rofi-emoji
    # firefox
    # comic-mono
    # (pkgs.nerdfonts.override {
    #   fonts = [ "FiraCode"   "Monofur" ];
    # })
  ];


  # services
  services = {
    #    emacs = {
    #      enable = true;
    #      client.enable =true;
    #      socketActivation.enable = true;
    #    };
    # # dunst = {
    #  enable = true;
    #  iconTheme = pkgs.papirus-icon-theme; 
    # };
  };

  # direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # foot
  programs.foot = {
    enable = true;
  };


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
  home.file."/home/drishal/.config/deadd".source = ../config/deadd;

  # rofi
  # home.file."/home/drishal/.config/rofi/config.rasi".source = ../config/rofi/config.rasi;

  # home.file."/home/drishal/.config/rofi/config".source = ../config/rofi/config;

  # setting Xresources
  # home.file."/home/drishal/.Xresources".source = ../.Xresources;

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

  # conky
  home.file."/home/drishal/.config/conky/onedark.conkyrc".source = ../config/conky/onedark.conkyrc;
  # qtile config
  #home.file."/home/drishal/.config/qtile/config.py".source =../config/qtile/config.py;
  # home.file."/home/drishal/.config/qtile/autostart.sh".source =../config/qtile/autostart.sh;


  # home.stateVersion = "21.05";
}

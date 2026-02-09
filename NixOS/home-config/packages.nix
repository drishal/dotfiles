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
    #basedpyright
    cachix
    cowsay
    # inputs.eww.packages.${pkgs.stdenv.hostPlatform.system}.eww
    emacs-lsp-booster
    fd
    fzf
    ispell
    glibcLocales
    lua-language-server
    man
    man-pages
    nixd
    neofetch
    # nvchad
    # neovim
    #rnix
    # sl
    starship
    # neovide
    # nixpkgs-fmt
    nixfmt-rfc-style
    # nil
    taplo
    # papirus-icon-theme
    gnome-themes-extra
    gjs
    hexedit
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
    wrapGAppsHook3
    gobject-introspection
    # hyprpanel
    # inputs.ags.packages.${pkgs.system}.agsFull
    # inputs.ags.packages.${pkgs.system}.astal4
    # inputs.astal.packages.${pkgs.system}.tray
    # inputs.astal.packages.${pkgs.system}.hyprland
    # inputs.astal.packages.${pkgs.system}.io
    # inputs.astal.packages.${pkgs.system}.apps
    # inputs.astal.packages.${pkgs.system}.battery
    # inputs.astal.packages.${pkgs.system}.bluetooth
    # inputs.astal.packages.${pkgs.system}.mpris
    # inputs.astal.packages.${pkgs.system}.network
    # inputs.astal.packages.${pkgs.system}.notifd
    # inputs.astal.packages.${pkgs.system}.powerprofiles
    # inputs.astal.packages.${pkgs.system}.wireplumber
    glib
    (python3.withPackages (
      ps: with ps; [
        pygobject3
        pygobject-stubs

        (inputs.ignis.packages.${pkgs.stdenv.hostPlatform.system}.ignis.override {
          extraPackages = [
            psutil
            jinja2
            pillow
            materialyoucolor
            pygobject3
            pygobject-stubs
          ];
        })
      ]
    ))

    # (pkgs.python3.withPackages (pp: [
    #   pp.pygobject3
    #   pp.pygobject-stubs
    #   (inputs.ignis.packages.${pkgs.stdenv.hostPlatform.system}.ignis.override {
    #     extraPackages = [
    #       # Add extra packages if needed
    #       psutil
    #       jinja2
    #       pillow
    #       materialyoucolor
    #     ];
    #   })
    # ]))
  ];

  #nixd path
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  # ags
  # programs.ags = {
  #   enable = true;
  #   configDir = null;
  #   extraPackages = with pkgs; [
  #     gtksourceview
  #     webkitgtk
  #     accountsservice
  #   ];
  # };
  # home.file."${config.home.homeDirectory}/.config/ags/" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/ags/";
  #   recursive = true;
  # };
  # home.file."${config.home.homeDirectory}/.config/css/ags-color.css".text = with config.lib.stylix.colors;  ''
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
  # '';
  home.file."${config.home.homeDirectory}/.config/css/ags-color.scss".text =
    with config.lib.stylix.colors; ''
      $colbg: #${base00}; 
      $colbg2:  #${base02};
      $colfg:  #${base05};
      $colgrey:  #${base03};
      $colcyan:  #${base0C};
      $colgreen:  #${base0B};
      $colorange:  #${base09};
      $colmagenta:  #${base0E};
      $colviole:  #${base0F};
      $colred:  #${base08};
      $colyellow:  #${base0A};
    '';

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
  # programs.lsd = {
  #   enable = true;
  #   enableZshIntegration = false;
  #   settings = {
  #     icons = {
  #       theme = "fancy";
  #       separator = "  ";
  #     };
  #   };
  # };

  gtk = {
    enable = true;
      gtk2.extraConfig = ''
      gtk-button-images=1
      gtk-menu-images=1
    '';
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-button-images = 1;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-animations = true;
      gtk-menu-images = 1;
      gtk-modules = "colorreload-gtk-module";
      gtk-primary-button-warps-slider = false;
      gtk-enable-event-sounds = 1;
      gtk-enable-input-feedback-sounds = 1;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintmedium";
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-cursor-theme-size = 24;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-animations = true;
      gtk-modules = "colorreload-gtk-module";
      gtk-primary-button-warps-slider = "false";
    };
  };

  # zellij
  programs.zellij = {
    enable = true;
    enableBashIntegration = false;
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
  # programs.fastfetch = {
  #   enable = true;
  #   settings  = {
  #     logo = {
  #       type = "small";
  #     };
  #   };
  # };

  programs.gh.enable = true;
  services.swaync = {
    enable = true;
  };

  programs.fastfetch = {
    enable = true;
    settings = {

      schema = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
      logo = {
        type = "small";
      };

      display = {
        key.width = 4;
        separator = " ";
        size.binaryPrefix = "si";
      };

      modules = [
        {
          format = "{3}";
          key = " ";
          keyColor = "green";
          type = "os";
        }

        {
          key = " ";
          keyColor = "yellow";
          type = "kernel";
        }

        {
          key = " ";
          keyColor = "blue";
          type = "uptime";
        }

        {
          key = "󰏖 ";
          keyColor = "magenta";
          type = "packages";
        }

        "break"

        {
          format = "{1} ({5})";
          key = " ";
          keyColor = "green";
          type = "cpu";
        }

        {
          driverSpecific = true;
          format = "{2}";
          #hideType = "integrated";
          key = " ";
          keyColor = "yellow";
          type = "gpu";
        }

        {
          format = "{/1}{-}{/}{/2}{-}{/}{} / {}";
          key = " ";
          keyColor = "blue";
          type = "memory";
        }

        {
          key = "󰌢 ";
          type = "host";
          keyColor = "red";
        }

        "break"

        {
          compactType = "scaled";
          key = "󰍹 ";
          keyColor = "cyan";
          type = "display";
        }

        {
          format = "{2}";
          key = " ";
          keyColor = "green";
          type = "wm";
        }

        {
          format = "{3}";
          key = " ";
          keyColor = "yellow";
          type = "terminal";
        }

        {
          key = " ";
          keyColor = "blue";
          type = "shell";
        }

        "break"

        {
          key = " ";
          symbol = "circle";
          type = "colors";
        }
      ];

    };
  };

  # syncthing
  services.syncthing = {
    enable = true;
    guiAddress = "0.0.0.0:8384";
  };

}

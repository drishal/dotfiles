{
  config,
  inputs,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    bat
    cachix
    cowsay
    emacs-lsp-booster
    fd
    fzf
    ispell
    glibcLocales
    lua-language-server
    nixd
    playwright
    playwright-driver.browsers-chromium
    playwright-mcp
    starship
    nixfmt
    taplo
    gnome-themes-extra
    gjs
    hexedit
    wrapGAppsHook3
    gobject-introspection
    glib
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
    (pkgs.writers.writePython3Bin "porthistory" {
      # Add libraries your script needs
      libraries = with pkgs.python3Packages; [ pyyaml ];

      doCheck = false;
      # flake-utils or other extras if needed → usually not
    } (builtins.readFile ../../../../scripts/porthistory.py))

  ];

  #nixd path
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
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

  programs.gh.enable = true;

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.dircolors = {
    enable = true;
  };


  # syncthing
  services.syncthing = {
    enable = true;
    guiAddress = "0.0.0.0:8384";
  };

}

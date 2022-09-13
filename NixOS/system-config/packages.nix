{ config, pkgs, inputs, lib, ... }:
{
  services.flatpak.enable = true;
  services.gvfs.enable = true;
  xdg.portal.enable = true;
  programs = {
    # adb
    adb.enable = true;
    # dconf
    dconf.enable = true;
    # java 
    java = { enable = true; };
    # nm-applet
    nm-applet.enable = true;
    #steams
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # aqemu
    # batdistrack
    # brave
    # build tools
    # chromium
    # ciscoPacketTracer8
    # cloudflare-warp
    # ferdi
    # gnome.gnome-documents
    # hack-font
    # librewolf
    # lspci
    # mate.caja
    # node stuff 
    # python stuff
    # qutebrowser
    # rust stuff
    # some xfce apps
    # spotify
    # taffybar
    virt-manager
    # xfce.thunar
    # xfce.xfce4-power-manager
    # deadd-notification-center
    #nodepackages

    # Node stuff
    # python stuff
    ##
    ##
    acpi
    adwaita-qt 
    alacritty
    appimage-run
    arc-theme
    arandr
    scrcpy
    axel
    bat
    bc
    bison
    bookworm
    bottles
    bpytop
    bpytop
    brightnessctl
    cachix
    calibre
    cargo
    carnix
    chromium
    chromium-bsu
    cinnamon.nemo
    clang
    clang-tools
    cloudflare-warp
    cmake
    cmatrix
    conky
    cpufetch
    debootstrap
    discord
    distrobox
    dmenu
    dmidecode
    docker-compose
    dunst
    dwmblocks
    ed
    evince
    evince
    exa
    fdk_aac
    feh
    ffmpeg
    figlet
    file
    flameshot
    flex
    gcc
    gimp
    git
    gitRepo
    github-desktop
    glxinfo
    gnome.cheese
    gnome.gnome-calculator
    gnome.gnome-sound-recorder
    gnome.gnome-tweaks
    gnome.zenity
    gnumake
    gnupg
    gparted
    gtk-layer-shell
    haruna
    haskellPackages.xmobar
    htop
    imagemagick
    imagemagick
    inetutils
    inxi
    keepassxc
    killall
    kitty
    leafpad
    linuxKernel.packages.linux_5_19.v4l2loopback    
    libnotify
    libreoffice
    libva-utils
    linuxPackages.cpupower
    lm_sensors
    lolcat
    libsForQt5.ark
    lsd
    lshw
    lutris
    lxappearance
    lxsession
    man
    materia-theme
    mesa-demos
    mpv
    mullvad
    mullvad-vpn
    ncdu
    ncurses
    neofetch
    neovim
    networkmanagerapplet
    nitrogen
    nixpkgs-fmt
    nmap
    # nodePackages.javascript-typescript-langserver
    nodePackages.eslint
    nodePackages.js-beautify
    nodePackages.create-react-app
    nodePackages.pyright
    nodePackages.react-tools
    nodePackages.vscode-html-languageserver-bin
    nodejs
    noto-fonts
    ntfs3g
    obs-studio
    onefetch
    # onlyoffice-bin
    # geekbench
    pandoc
    papirus-icon-theme
    pass
    pavucontrol
    peaclock
    pfetch
    php
    pkg-config
    plasma5Packages.spectacle
    polybar
    powershell
    powertop
    protonvpn-cli
    protonvpn-gui
    protonup
    ps_mem
    python3
    # python3Packages.django
    python3Packages.mysql-connector
    python3Packages.pip
    python3Packages.tkinter
    # python3Packages.tk
    python3Packages.pyqt5
    python3Packages.venvShellHook
    qbittorrent
    qt5ct
    ranger
    redshift
    ripgrep
    rnix-lsp
    rofi
    rofi-emoji
    rustc
    rustup
    simplescreenrecorder
    smplayer
    speedtest-cli
    spot
    starship
    steam-run
    surf
    sway-contrib.grimshot
    swaybg
    tdesktop
    tetex
    thinkfan
    # teamviewer
    tigervnc
    tmux
    tor-browser-bundle-bin
    trayer
    tree
    unzip
    usbutils
    vim
    virtualenv
    vlc
    volumeicon
    # vscode
    waybar
    wget
    woeusb
    wine
    wine64
    wofi
    xarchiver
    yarn
    youtube-dl
    yt-dlp
    zip
    zoom-us

    # Xfce stuff
    (xfce.thunar.override { thunarPlugins = with pkgs; [ xfce.thunar-volman xfce.thunar-archive-plugin ]; })
    xclip
    xfce.exo
    xfce.xfce4-clipman-plugin
    xfce.xfce4-notifyd
    xfce.xfce4-taskmanager
    xfce.xfce4-whiskermenu-plugin
    xfce.xfconf

    ## Xorg stuff
    xorg.xbacklight
    xorg.xdpyinfo
    xorg.xf86videoamdgpu
    xorg.xkill
    xorg.xmodmap


    # python39Packages.numpy python39Packages.pandas
    #     ((emacsPackagesFor emacsPgtkGcc).emacsWithPackages
    #       (epkgs: [
    #         epkgs.vterm]))
    # (pkgs.callPackage ../packages/batdistrack/default.nix { })
    # picom
    #(distrobox.overrideAttrs)
    (st.overrideAttrs (oldAttrs: rec {
      patches = [
        # You can specify local patches
        # ./path/to/local.diff
        # Fetch them directly from `st.suckless.org`
        # (fetchpatch {
        #   url = "https://st.suckless.org/patches/rightclickpaste/st-rightclickpaste-0.8.2.diff";
        #   sha256 = "1y4fkwn911avwk3nq2cqmgb2rynbqibgcpx7yriir0lf2x2ww1b6";
        # })
        # (fetchpatch {
        #   url = "http://st.suckless.org/patches/xresources/st-xresources-20200604-9ba7ecf.diff";
        #   sha256 = "sha256-8HV66XrTJu80H0Mwws5QL7BV6L9omUH6avFJqdDC7as=";
        # })
        (fetchpatch {
          url = "http://st.suckless.org/patches/desktopentry/st-desktopentry-0.8.4.diff";
          sha256 = "sha256-Hj2YgKHXhRplT8ojGCktygwKPdvaY9l2pteLunz1EGw=";
        })
      ];
    }))
    (picom.overrideAttrs (_: {
      src = pkgs.fetchFromGitHub {
        repo = "picom";
        owner = "yshui";
        rev = "affe408d76548d0df523f6b197072fea33c3c041";
        sha256 = "sha256-zQ6vkHCxt/IUFZEqYNO2PWle7YfqWBtI7GmGtzOSau4=";
      };
    }))
    # (discord.overrideAttrs (_: {
    #   extraOptions = [
    #     "--disable-gpu-memory-buffer-video-frames"
    #     "--enable-accelerated-mjpeg-decode"
    #     "--enable-accelerated-video"
    #     "--enable-gpu-rasterization"
    #     "--enable-native-gpu-memory-buffers"
    #     "--enable-zero-copy"
    #     "--ignore-gpu-blocklist"
    #   ];
    # }))
    # river
    (river.overrideAttrs (prevAttrs: rec {
      postInstall =
        let
          riverSession = ''
            [Desktop Entry]
            Name=River
            Comment=Dynamic Wayland compositor
            Exec=river
            Type=Application
          '';
        in
        ''
          mkdir -p $out/share/wayland-sessions
          echo "${riverSession}" > $out/share/wayland-sessions/river.desktop
        '';
      passthru.providedSessions = [ "river" ];
    }))
  ];

  # powerManagement = {
  #   powerDownCommands = ''
  #     ${pkgs.batdistrack}/bin/batdistrack
  #   '';
  # };

  # # nixpkgs.overlays = [
  #   # batdistrack
  #   (self: super: {
  #     batdistrack = super.callPackage ../extra-packages/batdistrack/default.nix { };
  #   })
  # ];
  services.teamviewer.enable = true;
  systemd.packages = with pkgs; [ cloudflare-warp ];

  #environment 
    environment.sessionVariables = rec {
      XDG_CACHE_HOME  = "\${HOME}/.cache";
      XDG_CONFIG_HOME = "\${HOME}/.config";
      XDG_BIN_HOME    = "\${HOME}/.local/bin";
      XDG_DATA_HOME   = "\${HOME}/.local/share";
      # Steam needs this to find Proton-GE
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
      # note: this doesn't replace PATH, it just adds this to it
      PATH = [ 
        "\${XDG_BIN_HOME}"
      ];
    };
  # mullvad
  # services.mullvad-vpn.enable = true;
}


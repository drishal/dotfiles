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
    # nodePackages.create-react-app
    # python stuff
    # qutebrowser
    # rust stuff
    # some xfce apps
    # spotify
    # taffybar
    # virt-manager
    # xfce.thunar
    # xfce.xfce4-power-manager
    #nodepackages
    acpi
    alacritty
    appimage-run
    arc-theme
    axel
    bat
    bc
    bison
    bookworm
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
    cmake
    cmatrix
    conky
    cpufetch
    deadd-notification-center
    debootstrap
    discord
    distrobox
    dmenu
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
    firefox
    flameshot
    flex
    gcc
    gimp
    git
    gitRepo
    github-desktop
    glxinfo
    gnome.gnome-calculator
    gnome.gnome-sound-recorder
    gnome.gnome-tweaks
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
    libnotify
    libreoffice
    libva-utils
    linuxPackages.cpupower
    lm_sensors
    lolcat
    lsd
    lshw
    lxappearance
    lxsession
    man
    materia-theme
    mesa-demos
    mpv
    # mullvad
    # mullvad-vpn
    ncdu
    ncurses
    neofetch
    neovim
    networkmanagerapplet
    nitrogen
    nixpkgs-fmt
    nmap
    # Node stuff
    nodePackages.javascript-typescript-langserver
    nodePackages.js-beautify
    nodePackages.pyright
    nodePackages.react-tools
    nodePackages.vscode-html-languageserver-bin
    nodejs
    ##
    noto-fonts
    ntfs3g
    obs-studio
    onefetch
    pandoc
    papirus-icon-theme
    pass
    pavucontrol
    pfetch
    php
    pkg-config
    plasma5Packages.spectacle
    polybar
    powershell
    powertop
    protonvpn-cli
    protonvpn-gui
    ps_mem
    # python stuff
    python3
    python3Packages.pip
    python3Packages.venvShellHook
    python3Packages.mysql-connector
    ##
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
    thinkfan
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
    vscode
    waybar
    wget
    woeusb
    wofi
    xarchiver

    # Xfce stuff
    (xfce.thunar.override { thunarPlugins = with pkgs; [ xfce.thunar-volman xfce.thunar-archive-plugin ]; })
    xclip
    xfce.exo
    xfce.xfce4-clipman-plugin
    xfce.xfce4-notifyd
    xfce.xfce4-taskmanager
    xfce.xfce4-whiskermenu-plugin
    xfce.xfconf
    ##
    xorg.xbacklight
    xorg.xdpyinfo
    xorg.xf86videoamdgpu
    xorg.xkill
    xorg.xmodmap

    yarn
    youtube-dl
    yt-dlp
    zathura
    zip
    zoom-us


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
        rev = "cd50596f0ed81c0aa28cefed62176bd6f050a1c6";
        sha256 = "0lh3p3lkafkb2f0vqd5d99xr4wi47sgb57x65wa2cika8pz5sikv";
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

}


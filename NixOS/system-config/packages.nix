{ config, pkgs, inputs, lib, ... }:
{
  services.flatpak.enable = true;
  services.gvfs.enable = true;
  xdg.portal.enable = true;
  programs = {

    # java 
    java = { enable = true; };

    # nm-applet
    nm-applet.enable = true;

    # dconf
    dconf.enable = true;

    # adb
    adb.enable = true;
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    # aqemu
    simplescreenrecorder
    debootstrap
    mate.caja
    imagemagick
    pandoc
    obs-studio
    ffmpeg
    php
    yt-dlp
    # virt-manager
    vim
    haskellPackages.xmobar
    flameshot
    alacritty
    xorg.xkill
    lshw
    # lspci
    bookworm
    distrobox
    calibre
    git
    man
    papirus-icon-theme
    xorg.xf86videoamdgpu
    lxappearance
    figlet
    lxsession
    bc
    libnotify
    xclip
    starship
    cmake
    volumeicon
    usbutils
    pavucontrol
    killall
    htop
    bpytop
    firefox
    neofetch
    steam-run
    inxi
    # hack-font
    xarchiver
    unzip
    zip
    nitrogen
    rofi
    trayer
    arc-theme
    youtube-dl
    mpv
    smplayer
    pfetch
    qbittorrent
    mesa-demos
    rofi-emoji
    glxinfo
    xorg.xdpyinfo
    evince
    qt5ct
    ncurses
    redshift
    xorg.xbacklight
    brightnessctl
    imagemagick
    exa
    lsd
    chromium-bsu
    gcc
    deadd-notification-center
    zoom-us
    linuxPackages.cpupower
    gnome.gnome-tweaks
    powertop
    inetutils
    nmap
    cpufetch
    dmenu
    cmatrix
    # qutebrowser
    neovim
    libreoffice
    # nodePackages.create-react-app
    nodejs
    yarn
    nodePackages.react-tools
    ranger
    xorg.xmodmap
    powershell
    gimp
    # brave
    thinkfan
    tigervnc
    bpytop
    bat
    polybar
    lolcat
    ncdu
    lm_sensors
    rnix-lsp
    plasma5Packages.spectacle
    gnome.gnome-sound-recorder
    tmux
    ps_mem
    # taffybar
    noto-fonts
    ntfs3g
    gparted
    file
    appimage-run
    woeusb
    cachix
    feh
    cinnamon.nemo
    libva-utils
    speedtest-cli
    pass
    surf
    gnumake
    clang-tools
    ed
    materia-theme
    discord
    waybar
    swaybg
    pkg-config
    kitty
    sway-contrib.grimshot
    wofi
    dunst
    networkmanagerapplet
    tree
    dwmblocks
    conky
    batdistrack
    # ciscoPacketTracer8
    onefetch
    ripgrep
    nixpkgs-fmt
    clang
    fdk_aac
    keepassxc
    gnupg
    axel
    haruna
    gnome.gnome-calculator
    vlc
    # ferdi
    tdesktop
    gtk-layer-shell
    # build tools
    flex
    bison
    gitRepo
    docker-compose
    #rust home-manager metasploit theharvester
    cargo
    carnix
    # python stuff
    python3
    python3Packages.pip
    python3Packages.venvShellHook
    virtualenv
    # some xfce apps
    xfce.xfce4-clipman-plugin
    xfce.xfconf
    xfce.exo
    # xfce.thunar
    (xfce.thunar.override { thunarPlugins = with pkgs; [ xfce.thunar-volman xfce.thunar-archive-plugin ]; })
    xfce.xfce4-taskmanager
    xfce.xfce4-notifyd
    xfce.xfce4-whiskermenu-plugin
    # xfce.xfce4-power-manager

    #nodepackages
    nodePackages.pyright
    nodePackages.vscode-html-languageserver-bin


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

  nixpkgs.overlays = [
    # batdistrack
    (self: super: {
      batdistrack = super.callPackage ../extra-packages/batdistrack/default.nix { };
    })
  ];
  powerManagement = {
    powerDownCommands = ''
      ${pkgs.batdistrack}/bin/batdistrack
    '';
  };
}

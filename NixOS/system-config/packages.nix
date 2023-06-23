{ config, pkgs, inputs, lib, ... }:
{
  services.flatpak.enable = true;
  services.gvfs.enable = true;
  # xdg.portal.enable = true;
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

    #openvpn
    openvpn3.enable = true;

    #kde connect
    kdeconnect.enable=true;

    # systemtap
    # systemtap.enable=true;
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    acpi
    adwaita-qt 
    aircrack-ng
    # anydesk
    alacritty
    appimage-run
    arandr
    # arc-theme
    aria
    scrcpy
    axel
    bat
    bc
    bison
    bookworm
    (brave.override {
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--force-dark-mode"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,DCompTripleBufferVideoSwapChain"
        "--disable-features=UseChromeOSDirectVideoDecoder"
        "--ozone-platform-hint=auto"
        "--enable-accelerated-video-decode"
        "--enable-accelerated-video-encode"
        "--enable-hardware-overlays"
        "--disable-gpu-driver-bug-workarounds" 
        "--enable-native-gpu-memory-buffers" 
        "--enable-webrtc-hw-decoding" 
        "--enable-webrtc-hw-encoding"
      ];
    })
    # (brave.override {
    #   commandLineArgs = [
    #     "--disable-software-rasterizer"
    #     "--disable-gpu-driver-bug-workarounds"
    #     "--disable-gpu-driver-workarounds"
    #     "--enable-accelerated-video-decode"
    #     "--enable-accelerated-mjpeg-decode"
    #     "--enable-features=VaapiVideoDecoder,ParallelDownloading,UnexpireFlagsM90,VaapiVideoEncoder,CanvasOopRasterization,Vulkan,RawDraw"
    #     "--disable-features=UseChromeOSDirectVideoDecoder"
    #     "--enable-drdc"
    #     "--enable-gpu-compositing"
    #     "--enable-gpu-rasterization"
    #     "--enable-gpu-memory-buffer-video-frames"
    #     "--enable-hardware-overlays"
    #     "--enable-native-gpu-memory-buffers"
    #     "--enable-oop-rasterization"
    #     "--enable-zero-copy"
    #     "--ignore-gpu-blocklist"
    #   ];
    # })

    btop
    bun
    brightnessctl
    bridge-utils
    cachix
    # calibre
    cargo
    #carnix
    # chromium
    (chromium.override {
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--force-dark-mode"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
        "--disable-features=UseChromeOSDirectVideoDecoder"
        "--use-vulkan"
        "--ozone-platform-hint=auto"
        "--enable-hardware-overlays"
      ];
    })

    chromium-bsu
    cinnamon.nemo
    cinnamon.nemo-with-extensions
    # clang
    clang-tools
    # cloudflare-warp
    # (cloudflare-warp.overrideAttrs(_: {buildInputs=[pkgs.dbus pkgs.stdenv.cc.cc.lib];}))
    cmake
    cmatrix
    conky
    cpufetch
    debootstrap
    deluge
    dejavu_fonts
    # dolphin
    discord
    distrobox
    dmg2img
    dmenu
    dmidecode
    docker-compose
    dunst
    dwmblocks
    ed
    ethtool
    # etcher
    evince
    evince
    easyeffects
    extundelete
    exa
    # fastfetch
    fdk_aac
    feh
    fim
    ffmpeg-full
    # ff2mpv
    figlet
    #firefox-bin
    inputs.firefox-nightly.packages.${pkgs.system}.firefox-beta-bin
    # inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin
    # firefox-wayland
    # firefox-devedition-bin
    file
    # fish
    flameshot
    foremost
    flex
    gcc
    # geekbench
    # google-chrome
    (google-chrome.override {
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--force-dark-mode"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
        # "--disable-features=UseChromeOSDirectVideoDecoder"
        "--use-vulkan"
        "--ozone-platform-hint=auto"
        "--enable-hardware-overlays"
      ];
    })
    gimp
    git
    gitRepo
    glxinfo
    gns3-gui
    gns3-server
    gnome.gnome-boxes
    gnome.cheese
    gnome.gnome-calculator
    gnome.gnome-sound-recorder
    gnome.gnome-tweaks
    # gnome.nautilus
    gnome.zenity
    gnumake
    gnupg
    gsmartcontrol
    gparted
    gtk-layer-shell
    gtklock
    haruna
    haskellPackages.xmobar
    hdparm
    htop
    hollywood
    hyprpaper
    hyfetch
    hwinfo
    imagemagick
    imagemagick
    inetutils
    inxi
    inotify-tools
    python3Packages.ipython
    python3Packages.python-lsp-server
    keepassxc
    killall
    kitty
    kompose
    kubectl
    kubernetes
    leafpad
    #linuxKernel.packages.linux_5_19.v4l2loopback    
    libnotify
    libreoffice
    libva-utils
    libsixel
    libfaketime
    linuxPackages.cpupower
    lxqt.pcmanfm-qt
    # linuxPackages.systemtap
    # linuxKernel.packages.linux.systemtap
    lm_sensors
    lolcat
    libsForQt5.ark
    libsForQt5.okular 
    libsForQt5.konsole
    lsd
    lshw
    lutris
    lxappearance
    lxsession
    man
    materia-theme
    mesa-demos
    metasploit
    microsoft-edge
    mongodb-compass
    mosh
    motrix
    mplayer
    mpv
    #mullvad
    #mullvad-vpn
    ncdu
    ncurses
    neofetch
    nitch
    neovim
    neovide
    networkmanagerapplet
    nitrogen
    nim
    nixpkgs-fmt
    nmap
    nodejs
    # nodePackages_latest.create-react-app
    noto-fonts
    ntfs3g
    obs-studio
    okteto
    openvpn
    onefetch
    # onboard
    onlyoffice-bin
    p7zip
    pandoc
    papirus-icon-theme
    pass
    pavucontrol
    pciutils
    pcmanfm
    peaclock
    pfetch
    php
    pkg-config
    plasma5Packages.spectacle
    polybar
    podman-compose
    powershell
    postman
    poppler_utils
    powertop
    powercap
    protonvpn-cli
    protonvpn-gui
    procps
    protonup-qt
    ps_mem
    python3
    poppler
    pdfgrep
    # python3Packages.mysql-connector
    python3Packages.pip
    python3Packages.tkinter
    python3Packages.shodan
    python3Packages.pyqt5
    python3Packages.venvShellHook
    python3Packages.qtile-extras
    qbittorrent
    qt5ct
    qpdf
    ranger
    radeontop
    redshift
    read-edid
    ripgrep
    rnix-lsp
    rofi
    rofi-emoji
    rustc
    rustup
    rust-analyzer
    simplescreenrecorder
    sony-headphones-client
    smplayer
    speedtest-cli
    spot
    starship
    sass
    steam-run
    surf
    # swaylock
    sway-contrib.grimshot
    swaylock-effects
    swaybg
    tdesktop
    tetex
    texlive.combined.scheme-medium
    thinkfan
    # thorium
    inputs.self.packages.${pkgs.system}.thorium
    tigervnc
    tmux
    tofi
    tor-browser-bundle-bin
    toolbox
    trayer
    tree
    unrar
    unzip
    usbutils
    uutils-coreutils
    vim
    vdpauinfo
    virt-manager
    virtualenv
    (vivaldi.override {
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--force-dark-mode"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
        "--disable-features=UseChromeOSDirectVideoDecoder"
        # "--use-vulkan"
        "--ozone-platform-hint=auto"
        "--enable-hardware-overlays"
      ];
    })
    vivaldi-ffmpeg-codecs
    ventoy-full
    # vscode-fhs
    vlc
    vulkan-tools
    volumeicon
    # waybar-hyprland
    wget
    woeusb
    widevine-cdm
    wine
    win-virtio 
    wirelesstools
    wine64
    wofi
    wl-clipboard
    wlr-randr
    wdisplays
    xarchiver
    yarn
    youtube-dl
    yt-dlp
    zip
    zoom-us

    # Xfce stuff
    (xfce.thunar.override { thunarPlugins = with pkgs; [ xfce.thunar-volman xfce.thunar-archive-plugin ]; })
    xclip
    xdg-ninja
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
    xorg.xhost

    zathura
    # python39Packages.numpy python39Packages.pandas
    #     ((emacsPackagesFor emacsPgtkGcc).emacsWithPackages
    #       (epkgs: [
    #         epkgs.vterm]))
    # (pkgs.callPackage ../packages/batdistrack/default.nix { })
    # (pkgs.callPackage ../custom-packages/galaxy-buds-client/default.nix { })
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
    (picom.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        repo = "picom";
        owner = "yshui";
        rev = "cee12875625465292bc11bf09dc8ab117cae75f4";
        sha256 = "sha256-lVwBwOvzn4ro1jInRuNvn1vQuwUHUp4MYrDaFRmW9pc=";
      };
      buildInputs = old.buildInputs ++ [ pkgs.pcre2 ];
    }))
    # (tlp.overrideAttrs (old: {
    #   src = pkgs.fetchFromGitHub {
    #     repo = "linrunner";
    #     owner = "TLP";
    #     rev = "e9d49c30b0f074eaa91a3853182da7cf67ca8ab7";
    #     sha256 = "sha256-LVWBWOVZN4RO1JINRUNVN1VQUWUHUP4MYRDAFRMW9PC=";
    #   };
    # }))
    # (discord.overrideAttrs (_: {
    #   # extraOptions
    #   commandLineArgs = [
    #     "--ignore-gpu-blocklist"
    #     "--enable-gpu-rasterization"
    #     "--enable-zero-copy"
    #     "--force-dark-mode"
    #     "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
    #     "--disable-features=UseChromeOSDirectVideoDecoder"
    #     "--use-vulkan"
    #     "--ozone-platform-hint=auto"
    #     "--enable-hardware-overlays"
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
  # services.teamviewer.enable = true;
  systemd.packages = with pkgs; [
    # (cloudflare-warp.overrideAttrs(_: {buildInputs=[pkgs.dbus pkgs.stdenv.cc.cc.lib];}))
    # cloudflare-warp
    (cloudflare-warp.overrideAttrs (old: {
      src = pkgs.fetchurl {
        url = "https://pkg.cloudflareclient.com/pool/jammy/main/c/cloudflare-warp/cloudflare-warp_2023.3.470-1_amd64.deb";
        # sha256 = "sha256-AYnmisEQKFiEB2iRJifEqRbdzAyBcfrU0ITeUokKLag=";
        sha256 = lib.fakeHash;
      };
    }))
];

  
  #swaylock
  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

  nixpkgs.config.permittedInsecurePackages = [
    "electron-12.2.3"
  ];
  #fonts
  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
  #   (pkgs.nerdfonts.override {
  #     fonts = [ "FiraCode"   "Monofur" ];
  #   })
  ];

  # # mullvad
  # services.mullvad-vpn.enable = true;

  # chaotic bincache
  # chaotic.nyx.cache.enable = true;
  # programs.firefox.nativeMessagingHosts.ff2mpv=true;
}


{
  config,
  pkgs,
  inputs,
  pkgs-master,
  lib,
  ...
}:
{
  services.flatpak.enable = true;
  services.gvfs.enable = true;
  hardware.openrazer.enable = true;

  programs = {
    # dconf
    dconf.enable = true;

    # java
    java = {
      enable = true;
    };

    # nm-applet
    nm-applet.enable = true;

    #steams
    steam = {
      enable = true;
    };

    #kde connect
    kdeconnect.enable = true;

    #game mode
    gamemode.enable = true;

    #gamescope
    gamescope = {
      enable = true;
      capSysNice = true; # already probably set, but confirm
    };

    #appimage
    appimage = {
      enable = true;
      binfmt = true;
      package = pkgs.appimage-run.override {
        extraPkgs =
          pkgs: with pkgs; [
            webkitgtk_4_1
          ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    # _9base
    acpi
    argc
    android-tools
    (ani-cli.overrideAttrs (old: {
      src = inputs.ani-cli;
    }))
    appimage-run
    arandr
    aria2
    scrcpy
    bat
    bc
    bison
    # brave
    btop
    # pkgs-master.bun
    (bun.overrideAttrs (old: rec {                                                                                                                                                         
     version = "1.3.14";                                                                                                                                                                  
     src = pkgs.fetchurl {                                                                                                                                                                
       url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";                                                                                        
       hash = "sha256-lR7iruhV8IWVruxiJSJqKY0/6oOj3NZGXAnLzN9+hI8=";                                                                                                                      
     };                                                                                                                                                                                   
   }))
    brightnessctl
    bridge-utils
    bubblewrap
    cabextract
    cachix
    chntpw
    cargo
    clementine
    claude-code
    nemo
    nemo-with-extensions
    clang-tools
    cloudflare-warp
    # (cloudflare-warp.overrideAttrs(_: {buildInputs=[pkgs.dbus pkgs.stdenv.cc.cc.lib];}))
    # (cloudflare-warp.overrideAttrs (old: {
    #   src = pkgs.fetchurl {
    #     url = "https://pkg.cloudflareclient.com/pool/jammy/main/c/cloudflare-warp/cloudflare-warp_2023.3.470-1_amd64.deb";
    #     sha256 = "sha256-AYnmisEQKFiEB2iRJifEqRbdzAyBcfrU0ITeUokKLag=";
    #     # sha256 = lib.fakeHash;
    #   };
    #   unpackPhase = null;
    # }))
    cmake
    cmatrix
    conky
    cpufetch
    # cpu-x
    debian-goodies
    # deluge
    dejavu_fonts
    devenv
    vesktop
    distrobox
    dig
       dmg2img
    docker-compose
    dust
    ed
    element-desktop
    ethtool
    easyeffects
    eza
    lsd
    fastfetch
    fdk_aac
    feh
    ffmpeg-full
    # ff2mpv
    figlet
    firefox
    # inputs.firefox-nightly.packages.${pkgs.system}.firefox-beta-bin
    findutils
    file
    # fish
    flameshot
    fluent-reader
    foremost
    flex
    freetype
    fuse-overlayfs
    gcc
    # geekbench
    # inputs.ghostty.packages.x86_64-linux.default
    gimp
    git
    gitRepo
    cheese
    gnome-calculator
    gnome-sound-recorder
    gnumake
    gnupg
    gh
    ghostscript
    goverlay
    gsmartcontrol
    gpu-screen-recorder
    gpu-screen-recorder-gtk
    gparted
    gping
    hdparm
    htop
    # hollywood
    hyprpaper
    hyperfine
    himalaya
    hwinfo
    imagemagick
    imagemagick
    inetutils
    inxi
    icu
    inotify-tools
    # inputs.lobster.packages.x86_64-linux.lobster
    inputs.lobster.packages.x86_64-linux.lobster
    # inputs.quickemu.packages.${pkgs.stdenv.hostPlatform.system}.quickemu
    pkgs.quickemu
    jq
    #python3Packages.ipython
    # python3Packages.pyngrok
    # python3Packages.pygobject3
    basedpyright
    # python3Packages.pygobject3
    # python3Packages.pygobject-stubs
    # inputs.astal.packages.${system}.astal3
    # inputs.astal.packages.${system}.io
    # (inputs.ignis.packages.${pkgs.stdenv.hostPlatform.system}.ignis.override {
    #   extraPackages = [
    #     # Add extra dependencies here
    #     # For example:
    #     pkgs.python3Packages.psutil
    #     pkgs.python3Packages.jinja2
    #     pkgs.python3Packages.pillow
    #     pkgs.python3Packages.materialyoucolor
    #   ];
    # })
    keepassxc
    killall
    kdePackages.ark
    kdePackages.okular
    kdePackages.konsole
    kdePackages.qtstyleplugin-kvantum
    kdePackages.spectacle
    kdePackages.kirigami
    kitty
    kompose
    lbreakout2
    # linuxKernel.packages.v4l2loopback
    # linuxKernel.packages.linux_cachyos.v4l2loopback
    libnotify
    libarchive
    libreoffice
    libva-utils
    libsixel
    libfaketime
    libepoxy
    linuxPackages.cpupower
    lm_sensors
    lolcat
    lsd
    lshw
    lollypop
    lxsession
    lsof
    man
    mangohud
    materia-theme
    mesa-demos
    metasploit
    # mov-cli
    # (mov-cli.overrideAttrs (old: {
    #   src = pkgs.fetchFromGitHub {
    #     repo = "mov-cli";
    #     owner = "mov-cli";
    #     rev = "b667f747aaf10ca182c7405a37ceb3ed4520dde9";
    #     sha256 = "sha256-9kC0rHU73Umv6vEtFpc5agn/qUAsWxSQSgVXW4qvjKQ=";
    #   };
    #   buildInputs = old.buildInputs ++ [ pkgs.python311Packages.setuptools-scm ];
    # }))
    mlocate
    mission-center
    mosh
    mpv
    ncdu
    ncurses
    nicotine-plus
    networkmanagerapplet
    netcat-gnu
    # nil
    nim
    nitch
    nitrogen
    nixpkgs-fmt
    nmap
    nodejs
    nerd-font-patcher
    nvtopPackages.amd
    noto-fonts
    ntfs3g
    obs-studio
    okteto
    openssl
    openvpn
    onefetch
    onlyoffice-desktopeditors
    p7zip
    pandoc
    papirus-icon-theme
    pass
    pavucontrol
    patchelf
    pciutils
    pfetch
    php
    pkg-config
    powershell
    poppler-utils
    powertop
    powercap
    polychromatic
    procps
    pdfgrep
    poppler
    ps_mem
    python3
    python3Packages.pip
    playerctl
    qpdf
    qbittorrent
    ranger
    read-edid
    ripgrep
    rofi
    rquickshare
    rofi-emoji
    simplescreenrecorder
    # sony-headphones-client
    # scx
    # smplayer
    sass
    speedtest-cli
    starship
    steam-run
    steamcmd
    steamtinkerlaunch
    s-tui
    sway-contrib.grimshot
    socat
    swaylock-effects
    swaybg
    telegram-desktop
    tmate
    tetex
    # texlive.combined.scheme-full
    #texlive.combined.scheme-medium
    # thorium
    # inputs.self.packages.${pkgs.system}.freedownloadmanager
    #inputs.self.packages.${pkgs.system}.thorium
    # inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.astal
    tigervnc
    tmux
    tofi
    transmission_4
    # toolbox
    trashy
    # trayer
    tree
    unrar
    uv
    umu-launcher
    unzip
    usbutils
    upterm
    uutils-coreutils
    vim
    vdpauinfo
    # virt-manager
    virtualenv
    virtiofsd
    vscode-fhs
    vscode-langservers-extracted
    vlc
    vulkan-tools
    vulkan-loader
    virt-viewer
    # volumeicon
    # waybar-hyprland
    webcamoid
    wget
    woeusb
    widevine-cdm
    # wine
    # wineWow64Packages.staging
    virtio-win
    wirelesstools
    # wine64
    # wireshark
    wofi
    wl-clipboard
    cliphist
    wlr-randr
    wdisplays
    xarchiver
    yarn
    yad
    yt-dlp
    zip
    (thunar.override {
      thunarPlugins = with pkgs; [
        thunar-volman
        thunar-archive-plugin
      ];
    })
    xclip
    xdg-ninja
    xfce4-exo
    xfce4-clipman-plugin
    xfce4-notifyd
    xfce4-taskmanager
    xfce4-whiskermenu-plugin
    xfconf
    xdotool
    ## Xorg stuff
    xbacklight
    xdpyinfo
    xf86-video-amdgpu
    xkill
    xmodmap
    xhost
    xwininfo
    xinit
    zathura
    zenity
    zapzap
    # (pkgs.python3.withPackages (ps: [
    #   ps.pygobject3
    #   ps.pygobject-stubs
    #   inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.astal3
    # ]))
  ];

  systemd.packages = with pkgs; [
    # (cloudflare-warp.overrideAttrs(_: {buildInputs=[pkgs.dbus pkgs.stdenv.cc.cc.lib];}))
    cloudflare-warp
    # (cloudflare-warp.overrideAttrs (old: {
    #   src = pkgs.fetchurl {
    #     url = "https://pkg.cloudflareclient.com/pool/jammy/main/c/cloudflare-warp/cloudflare-warp_2023.3.470-1_amd64.deb";
    #     sha256 = "sha256-AYnmisEQKFiEB2iRJifEqRbdzAyBcfrU0ITeUokKLag=";
    #     # sha256 = lib.fakeHash;
    #   };
    #   unpackPhase = null;
    # }))
  ];

  #swaylock
  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

  fonts = {
    enableDefaultPackages = true;
    # fontDir.enable = true;
    packages = with pkgs; [
      maple-mono.NF
      maple-mono.Normal-NF
      maple-mono.variable
      nerd-fonts.fantasque-sans-mono
      nerd-fonts.monaspace
      nerd-fonts.noto
      nerd-fonts.symbols-only
      nerd-fonts.recursive-mono
      nerd-fonts.commit-mono
      nerd-fonts.monaspace
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-lgc-plus
      roboto
      roboto-serif
      googlesans-code
    ];
  };
  # command not found and nix-index setup:
  # programs.command-not-found.enable = true;
  # programs.nix-index =
  #   {
  #     enable = true;
  #     enableFishIntegration = true;
  #     enableBashIntegration = true;
  #     enableZshIntegration = true;
  #   };
  # programs.firefox.nativeMessagingHosts.ff2mpv=true;
  # Use nixpkgs' built-in programs.sqlite so command-not-found and man-db consume a database that matches the active nixpkgs revision. Overriding this with flake-programs-sqlite conflicts with the module default.
  # programs.command-not-found.dbPath = inputs.programsdb.packages.${pkgs.system}.programs-sqlite;
  programs.nix-ld.enable = true;

  # Libraries for non-Nix dynamically linked binaries (AppImages, Electron apps, games).
  # nix-ld intercepts the ELF interpreter and sets LD_LIBRARY_PATH from these.
  programs.nix-ld.libraries = with pkgs; [
    # ── Core (needed by almost everything) ──
    stdenv.cc.cc.lib
    zlib

    # ── Electron / Chrome / Chromium ──
    glib.out
    nss.out
    nspr
    atk.out
    at-spi2-atk.out
    cups.lib
    dbus.lib
    libxkbcommon
    pango.out
    cairo.out
    expat
    alsa-lib
    mesa.out
    libgbm
    gtk3.out
    gdk-pixbuf.out
    libudev-zero.out

    # ── X11 ──
    libxcomposite
    libxdamage
    libxtst
    libxrandr
    libxext
    libx11
    libxfixes
    libxcb.out

    # ── Games / Steam ──
    # from https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/games/steam/fhsenv.nix#L72-L79
    libGL
    libva

    # from https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/games/steam/fhsenv.nix#L124-L136
    fontconfig
    freetype
    libxt
    libxmu
    libogg
    libvorbis
    SDL
    SDL2_image
    glew_1_10
    libdrm
    libidn
    libepoxy
    tbb
  ];
}

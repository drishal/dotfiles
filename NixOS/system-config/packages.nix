{
  config,
  pkgs,
  inputs,
  pkgs-master,
  lib,
  ...
}:
{
  # imports = [
    # pkgs-master
    # inputs.lobster.packages.x86_64-linux.lobster
  # ];
  services.flatpak.enable = true;
  services.gvfs.enable = true;
  # inputs.nixpkgs-fix.packages.${pkgs.system}.
  services.zerotierone = {
    enable = true;
    # package = inputs.nixpkgs-master.legacyPackages.${pkgs.system}.zerotierone ;
    package = pkgs-master.zerotierone ;
    localConf.settings = { 
      softwareUpdate = "disable";
    };
  };
  # services.ngrok = {
  # enable = true;
  # extraConfigFiles = [
  #   "${inputs.private-stuff}/ngrok.txt"
  # ];
  # };
  # xdg.portal.enable = true;
  programs = {
    # adb
    adb.enable = true;
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
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };

    #kde connect
    kdeconnect.enable = true;

    #wireshark
    wireshark.enable = true;

    #game mode
    gamemode.enable = true;

    #gamescope
    gamescope.enable = true;

    #appimage
    appimage = {
      enable = true;
      binfmt = true;
    };


    #neovim
    # neovim = {
    #   enable = true;
    #   package = pkgs.neovim-nightly;
    #   configure = {
    #     packages.myVimPackage = with pkgs; {
    #       start = [ lua-language-server ];
    #     };
    #   };
    # };

    # systemtap
    # systemtap.enable=true;
  };

  #autocpufreq
  # services.auto-cpufreq =
  #   {
  #     enable = true;
  #     settings = {
  #       charger = {
  #         governor = "performance";
  #         turbo = "on";
  #       };
  
  #       battery = {
  #         governor = "schedutil";
  #         turbo = "auto";
  #       };
  #     };
  #   };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # _9base
    acpi
    argc
    adwaita-qt
    aircrack-ng
    anydesk
    alacritty
    # ani-cli
    (ani-cli.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        repo = "ani-cli";
        owner = "pystardust";
        rev = "e90dd8b50ac12ade21d74bc82a20c777bbb63e1f";
        sha256 = "sha256-0uSD+TMeKSSwB0f875MYsHAUlIKjmJmzEnT7Z3m8bnY=";
      };
    }))

    appimage-run
    arandr
    # arc-theme
    aria
    #scrcpy
    pkgs-master.scrcpy
    axel
    bat
    bc
    bison
    bookworm
    # brave
    (brave.override {
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
        "--ozone-platform-hint=auto"
        "--enable-features=AcceleratedVideoDecodeLinuxGL,VaapiVideoDecoder,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
      ];
    })
    btop
    bun
    brightnessctl
    bridge-utils
    bubblewrap
    cabextract
    cachix
    # calibre
    # cargo
    #carnix
    # chromium
    (chromium.override {
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
        "--ozone-platform-hint=auto"
        "--enable-features=AcceleratedVideoDecodeLinuxGL,VaapiVideoDecoder,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
      ];
    })

    # chromium-bsu
    nemo
    nemo-with-extensions
    # clang
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
    cpu-x
    # debootstrap
    debian-goodies
    deluge
    dejavu_fonts
    devenv
    # dolphin
    discord
    distrobox
    dig
    # (distrobox.overrideAttrs (old: {
    #   src = pkgs.fetchFromGitHub {
    #     repo = "distrobox";
    #     owner = "89luca89";
    #     rev = "3435f4d27070a99668bfa29a3e508db4ecc09009";
    #     sha256 = "sha256-UWrXpb20IHcwadPpwbhSjvOP1MBXic5ay+nP+OEVQE4=";
    #   };
    # }))
    dmg2img
    dmenu
    dmidecode
    docker-compose
    dunst
    dust
    dwmblocks
    dwarfs
    ed
    # emacs-lsp-booster
    element-desktop
    ethtool
    # etcher
    evince
    evince
    # easyeffects
    extundelete
    eza
    lsd
    fastfetch
    fdk_aac
    # floorp
    feh
    fim
    ffmpeg-full
    # ff2mpv
    figlet
    # firefox-bin
    firefox
    inputs.quickemu.packages.${pkgs.stdenv.hostPlatform.system}.quickemu
    # firefox-wayland
    # inputs.firefox-nightly.packages.${pkgs.system}.firefox-beta-bin
    # inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin
    # firefox-wayland
    # firefox-devedition-bin
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
    geekbench
    # inputs.ghostty.packages.x86_64-linux.default
    # google-chrome
    # (google-chrome.override {
    #   commandLineArgs = [
    #     "--ignore-gpu-blocklist"
    #     "--enable-gpu-rasterization"
    #     "--enable-zero-copy"
    #     "--force-dark-mode"
    #     "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
    #     # "--disable-features=UseChromeOSDirectVideoDecoder"
    #     "--use-vulkan"
    #     "--ozone-platform-hint=auto"
    #     "--enable-hardware-overlays"
    #   ];
    # })
    gimp
    git
    gitRepo
    glxinfo
    # gns3-gui
    # gns3-server
    # gnome-boxes
    cheese
    gnome-calculator
    # gnome-sound-recorder
    # gnome-tweaks
    # gnome.nautilus
    # gnome.zenity
    gnumake
    gnupg
    ghostscript
    # go
    goverlay
    gsmartcontrol
    gparted
    gpt4all
    gtk-layer-shell
    gtklock
    # haruna
    haskellPackages.xmobar
    handbrake
    hdparm
    htop
    # hollywood
    hyprpaper
    hyperfine
    hwinfo
    imagemagick
    imagemagick
    inetutils
    inxi
    inotify-tools
    inputs.lobster.packages.x86_64-linux.lobster
    jq
    #python3Packages.ipython
    # python3Packages.pyngrok
    # python3Packages.pygobject3
    python3Packages.python-lsp-server
    # python3Packages.pygobject3
    # python3Packages.pygobject-stubs
    # inputs.astal.packages.${system}.astal3
    # inputs.astal.packages.${system}.io
    keepassxc
    killall
    kitty
    kompose
    kotatogram-desktop
    kubectl
    kubernetes
    lbreakout2
    # linuxKernel.packages.v4l2loopback
    # linuxKernel.packages.linux_cachyos.v4l2loopback
    libnotify
    libarchive
    libreoffice
    libva-utils
    libsixel
    libfaketime
    linuxPackages.cpupower
    # lxqt.pcmanfm-qt
    # linuxPackages.systemtap
    # linuxKernel.packages.linux.systemtap
    lm_sensors
    lolcat
    libsForQt5.ark
    libsForQt5.okular
    libsForQt5.konsole
    libsForQt5.qtstyleplugin-kvantum
    lsd
    lshw
    lutris-unwrapped
    lxappearance
    pkgs-master.lxsession
    man
    mangohud
    materia-theme
    (materia-kde-theme.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        repo = "materia-kde";
        owner = "PapirusDevelopmentTeam";
        rev = "6cc4c1867c78b62f01254f6e369ee71dce167a15";
        sha256 = "sha256-tZWEVq2VYIvsQyFyMp7VVU1INbO7qikpQs4mYwghAVM=";
      };
    }))
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
    # mongodb-compass
    mosh
    motrix
    # mplayer
    mpv
    #mullvad
    #mullvad-vpn
    # neovide
    ncdu
    ncurses
    neofetch
    # neovim-nightly
    networkmanagerapplet
    netcat-gnu
    # nil
    nim
    nitch
    nitrogen
    nixpkgs-fmt
    nmap
    nodejs
    # nvtop-amd
    nvtopPackages.amd
    # nodePackages_latest.create-react-app
    # nodePackages_latest.bash-language-server
    nodePackages_latest.typescript-language-server
    noto-fonts
    ntfs3g
    obs-studio
    okteto
    openvpn
    onefetch
    # onboard
    onlyoffice-bin
    (orchis-theme.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        repo = "Orchis-theme";
        owner = "vinceliuice";
        rev = "c774328344413a7ea416da242cc50e8cc1a99caa";
        sha256 = "sha256-COOmg7XW79iH/H+o81nfW+mrMjyii8jhmlP48lI2SGg=";
      };
    }))
    p7zip
    pandoc
    papirus-icon-theme
    pass
    pavucontrol
    # pwvucontrol
    patchelf
    pciutils
    # pkgs-master.pcmanfm
    peaclock
    pfetch
    php
    pkg-config
    plasma5Packages.spectacle
    polybar
    podman-compose
    powershell
    #postman
    poppler_utils
    powertop
    powercap
    # protonvpn-cli
    # protonvpn-gui
    procps
    pdfgrep
    poppler
    protonup-qt
    prow
    ps_mem
    python3
    # python3Packages.mysql-connector
    python3Packages.pip
    #python3Packages.tkinter
    #python3Packages.shodan
    #python3Packages.pyqt5
    #python3Packages.venvShellHook
    #$python3Packages.qtile-extras
    qpdf
    libsForQt5.qt5ct
    # quickemu
    # (quickemu.override { qemu = qemu_full; })
    # qutebrowser
    qbittorrent
    qbittorrent-nox
    # qtile-extras_git
    ranger
    radeontop
    redshift
    read-edid
    ripgrep
    # rnix-lsp
    rofi
    rofi-emoji
    # rustc
    # rustup
    # rust-analyzer
    simplescreenrecorder
    # sony-headphones-client
    # scx
    # smplayer
    sass
    speedtest-cli
    spot
    starship
    steam-run
    stremio
    s-tui
    surf
    # swaylock
    svp
    sway-contrib.grimshot
    swaylock-effects
    swaybg
    # telegram-desktop
    tmate
    tetex
    #texlive.combined.scheme-medium
    thinkfan
    # thorium
    # inputs.self.packages.${pkgs.system}.freedownloadmanager
    #inputs.self.packages.${pkgs.system}.thorium
    # inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.astal

    tigervnc
    tmux
    tofi
    tor-browser-bundle-bin
    # toolbox
    trashy
    trayer
    tree
    unrar
    unzip
    usbutils
    uutils-coreutils
    vim
    vdpauinfo
    # virt-manager
    virtualenv
    virtiofsd
    (vivaldi.override {
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
        "--ozone-platform-hint=auto"
        "--enable-features=AcceleratedVideoDecodeLinuxGL,VaapiVideoDecoder,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
      ];
    })
    vivaldi-ffmpeg-codecs
    ventoy-full
    vscode-fhs
    vscode-langservers-extracted
    vlc
    vulkan-tools
    volumeicon
    # waybar-hyprland
    webcamoid
    wget
    woeusb
    widevine-cdm
    # wine
    # wineWow64Packages.staging
    win-virtio
    wirelesstools
    # wine64
    # wireshark
    wofi
    wl-clipboard
    wlr-randr
    wdisplays
    xarchiver
    xonotic
    yarn
    yad
    yt-dlp
    # ytfzf
    zip
    # zoom-us
    # Xfce stuff
    (xfce.thunar.override {
      thunarPlugins = with pkgs; [
        xfce.thunar-volman
        xfce.thunar-archive-plugin
      ];
    })
    xclip
    xdg-ninja
    xfce.exo
    xfce.xfce4-clipman-plugin
    xfce.xfce4-notifyd
    xfce.xfce4-taskmanager
    xfce.xfce4-whiskermenu-plugin
    xfce.xfconf
    xdotool
    ## Xorg stuff
    xorg.xbacklight
    xorg.xdpyinfo
    xorg.xf86videoamdgpu
    xorg.xkill
    xorg.xmodmap
    xorg.xhost
    xorg.xwininfo
    zathura
    # zed-editor
    zenity
    # (pkgs.python3.withPackages (ps: [
    #   ps.pygobject3
    #   ps.pygobject-stubs
    #   inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.astal3
    # ]))
    # inputs.emacs-ng.packages.x86_64-linux.default
    # python39Packages.numpy python39Packages.pandas
    # ((emacsPackagesFor emacs-pgtk).emacsWithPackages (
    #   epkgs: with epkgs; [
    #     treesit-grammars.with-all-grammars
    #     vterm
    #     dockerfile-language-server-nodejs
    #     # telega
    #   ]
    # ))
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
    # (picom.overrideAttrs (old: {
    #   src = pkgs.fetchFromGitHub {
    #     repo = "picom";
    #     owner = "yshui";
    #     rev = "cee12875625465292bc11bf09dc8ab117cae75f4";
    #     sha256 = "sha256-lVwBwOvzn4ro1jInRuNvn1vQuwUHUp4MYrDaFRmW9pc=";
    #   };
    #   buildInputs = old.buildInputs ++ [ pkgs.pcre2 ];
    # }))
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
    # (river.overrideAttrs (prevAttrs: rec {
    #   postInstall =
    #     let
    #       riverSession = ''
    #         [Desktop Entry]
    #         Name=River
    #         Comment=Dynamic Wayland compositor
    #         Exec=river
    #         Type=Application
    #       '';
    #     in
    #     ''
    #       mkdir -p $out/share/wayland-sessions
    #       echo "${riverSession}" > $out/share/wayland-sessions/river.desktop
    #     '';
    #   passthru.providedSessions = [ "river" ];
    # }))
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

  nixpkgs.config.permittedInsecurePackages = [ "electron-12.2.3" ];
  #fonts
  fonts = {
    enableDefaultPackages = true;
    # fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      nerd-fonts.fantasque-sans-mono
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Sans" ];
        sansSerif = [ "Noto Serif" ];
        monospace = [ "FantasqueSansM Nerd Font" ];
      };
    };
  };
  # programs.command-not-found.enable = true;
  # programs.nix-index =
  #   {
  #     enable = true;
  #     enableFishIntegration = true;
  #     enableBashIntegration = true;
  #     enableZshIntegration = true;
  #   };
  # # mullvad
  # services.mullvad-vpn = {
  #   enable = true;
  #   package = pkgs.mullvad-vpn;
  # };

  #samba
  services.samba = {
    enable = true;
  };

  #nixd setting
  #nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

  # chaotic bincache
  # chaotic.nyx.cache.enable = true;
  # programs.firefox.nativeMessagingHosts.ff2mpv=true;
  programs.command-not-found.dbPath = inputs.programsdb.packages.${pkgs.system}.programs-sqlite;
  programs.nix-ld.enable = true;

  # "minimum" amount of libraries needed for most games to run without steam-run
  programs.nix-ld.libraries = with pkgs; [
    # common requirement for several games
    stdenv.cc.cc.lib

    # from https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/games/steam/fhsenv.nix#L72-L79
    xorg.libXcomposite
    xorg.libXtst
    xorg.libXrandr
    xorg.libXext
    xorg.libX11
    xorg.libXfixes
    libGL
    libva

    # from https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/games/steam/fhsenv.nix#L124-L136
    fontconfig
    freetype
    xorg.libXt
    xorg.libXmu
    libogg
    libvorbis
    SDL
    SDL2_image
    glew110
    libdrm
    libidn
    tbb
    zlib
  ];
}

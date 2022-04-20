{ config, pkgs, inputs, lib, ... }:
{
  programs = {

    # java 
    java = { enable = true; };

    # nm-applet
    nm-applet.enable = true;

    # dconf
    dconf.enable = true;
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    vim
    haskellPackages.xmobar
    alacritty
    xorg.xkill
    git
    man
    teams
    papirus-icon-theme
    xorg.xf86videoamdgpu
    lxappearance
    lxsession
    libnotify
    xclip
    starship
    cmake
    volumeicon
    usbutils
    pavucontrol
    killall
    htop
    firefox
    neofetch
    steam-run
    picom
    inxi
    hack-font
    xarchiver
    unzip
    nitrogen
    rofi
    trayer
    arc-theme
    youtube-dl
    xfce.xfce4-notifyd
    mpv
    smplayer
    pfetch
    qbittorrent
    mesa-demos
    glxinfo
    xorg.xdpyinfo
    evince
    qt5ct
    redshift
    xorg.xbacklight
    xfce.xfce4-power-manager
    brightnessctl
    imagemagick
    exa
    gcc
    deadd-notification-center
    nodePackages.pyright
    nodePackages.vscode-html-languageserver-bin
    zoom-us
    linuxPackages.cpupower
    powertop
    inetutils
    nmap
    cpufetch
    dmenu
    cmatrix
    qutebrowser
    neovim
    libreoffice
    nodePackages.create-react-app
    nodejs
    yarn
    nodePackages.react-tools
    ranger
    xorg.xmodmap
    powershell
    gimp
    brave
    thinkfan
    bpytop
    bat
    polybar
    lolcat
    ncdu
    lm_sensors
    rnix-lsp
    gnome.gnome-sound-recorder
    tmux
    ps_mem
    taffybar
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
    river
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
    ciscoPacketTracer8
    onefetch
    ripgrep
    nixpkgs-fmt
    clang
    fdk_aac
    keepassxc
    # some xfce apps
    xfce.xfce4-clipman-plugin
    xfce.thunar
    xfce.xfce4-taskmanager
    ferdi

    # autoconf automake inkscape gdk-pixbuf sassc pkgconfig
    # emacsPgtkGcc
    #rust home-manager metasploit theharvester
    cargo
    carnix
    # python stuff
    python39
    # python39Packages.numpy python39Packages.pandas
    #     ((emacsPackagesFor emacsPgtkGcc).emacsWithPackages
    #       (epkgs: [
    #         epkgs.vterm]))
  ];

}

{ config, pkgs, inputs, lib, ... }:
{
  services.flatpak.enable = true;
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
    vim
    haskellPackages.xmobar
    alacritty
    xorg.xkill
    git
    man
    papirus-icon-theme
    xorg.xf86videoamdgpu
    lxappearance
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
    firefox
    neofetch
    steam-run
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
    rofi-emoji
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
    chromium-bsu
    gcc
    deadd-notification-center
    nodePackages.pyright
    nodePackages.vscode-html-languageserver-bin
    zoom-us
    linuxPackages.cpupower
    gnome.gnome-tweaks
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
    plasma5Packages.spectacle
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
    ciscoPacketTracer8
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
    # some xfce apps
    xfce.xfce4-clipman-plugin
    xfce.thunar
    xfce.xfce4-taskmanager
    ferdi
    gtk-layer-shell
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
    # (pkgs.callPackage ../packages/batdistrack/default.nix { })
    # picom
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

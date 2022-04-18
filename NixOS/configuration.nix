{ config, pkgs,inputs, lib ,... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  # kernel parameters
  boot.kernelParams = ["iommu=pt"];

  # microde
  hardware.cpu.amd.updateMicrocode = true;

  nix.trustedUsers = [ "root" "drishal" ];
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #qt_qpa_platformtheme
 environment.variables.QT_QPA_PLATFORMTHEME = lib.mkForce "";


  #bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  networking.hostName = "nixos"; # Define your hostname.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # firmware updator
  services.fwupd.enable = true;
  # cpu governor
  powerManagement =
    {
      enable = true;
      cpuFreqGovernor="schedutil";
    };
    # open cl
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  #Vulkan
  hardware.opengl.driSupport = true;

  #docker
  virtualisation.docker.enable = true;
  # For 32 bit applications
  hardware.opengl.driSupport32Bit = true;
  # setting the video driver
  services.xserver.videoDrivers = [ "amdgpu" ];
  # enable opengl
  hardware.opengl.enable = true;
  # services.xserver.useGlamor = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # nixUnstable
  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
      experimental-features = nix-command flakes
      extra-sandbox-paths = /nix/var/cache/ccache
   '';
  # non-free stuff
  nixpkgs.config.allowUnfree = true;
  hardware.enableRedistributableFirmware=true;

  #optimizing storage in nixos
  # nix.autoOptimiseStore = true;
  nix.settings.auto-optimise-store = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  #networking.useDHCP = false;
  #networking.interfaces.enp0s3.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };
  # zsh
  # programs.zsh.enable = true;

  # kernel
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackages_zen;
    # Enable the Desktop Environment/Window managers.
  services.xserver = {
    enable = true;

    # window wmanagers
    windowManager = {
      qtile.enable = true;

      xmonad  = {
        enable = true;
        enableContribAndExtras = true;
      };


      awesome.enable = true;
      dwm.enable = true;
    };

    # Desktop Environment
    desktopManager = {
      plasma5.enable = true;
      xfce.enable = true;
      # lxqt.enable = true;
      # gnome.enable = true;
    };
    # windowManager = {
    #   session = pkgs.lib.singleton {
    #     name = "river";
    #     start = ''
    #     river &
    #     waitPID=$!
    #   '';
    #   };
    # };
    # displayManager.gdm.enable = true;
    displayManager.sddm.enable = true;
    # displayManager.lightdm = {
    #   enable = true;
    #   greeter.enable = true;
    # };
    # displayManager.session = [
    #   {
    #     manage = "window";
    #     name = "river";
    #     start = ''
    #     exec ${pkgs.river}/bin/river & 
    #     '';
    #   }
    # ];
  };
          # systemd-cat -t river -- ${pkgs.river}/bin/river &
          # waitPID=$!

  # fprint
  # services.fprintd.enable = true;
  services.xserver.displayManager.sessionPackages=[pkgs.river];
  services.gnome.tracker.enable = false;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  # resolve gnome and plasma issues
  #programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.plasma5Packages.ksshaskpass.out}/bin/ksshaskpass";
  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.x11_ssh_askpass}/libexec/x11-ssh-askpass";

  # Networking
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  # Configure keymap in X11
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # services.logind.lidSwitch = "suspend"; 
  # Enable sound.
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    wireplumber.enable = true;
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

  # use the example session manager (no others are packaged yet so this is enabled by default,
  # no need to redefine it in your config for now)
  # media-session.enable = true;
  };
  hardware.pulseaudio.enable = false;
  # some pulseaudio settings
  #hardware.pulseaudio.extraConfig =  "load-module module-suspend-on-idle";

  # backlight
  hardware.acpilight.enable = true;

  # systemd scripts
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.drishal = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel"  "network" "video"  "-manager" "docker"]; # Enable ‘sudo’ for the user.
  };
  security.sudo.extraConfig = ''
    Defaults 	insults
    '';
  #jaba
  programs.java = { enable = true ; };

  # river
  # options.programs.river = true;

  # nm-applet
  programs.nm-applet.enable=true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim haskellPackages.xmobar
    alacritty xorg.xkill git
    man teams 
    papirus-icon-theme xorg.xf86videoamdgpu lxappearance
    lxsession libnotify xclip starship
    cmake volumeicon usbutils
    pavucontrol killall htop
    firefox chromium neofetch steam-run 
    picom inxi hack-font xarchiver unzip
    nitrogen rofi trayer arc-theme
    youtube-dl
    xfce.xfce4-notifyd mpv smplayer pfetch
    qbittorrent  mesa-demos glxinfo
    xorg.xdpyinfo evince qt5ct
    redshift xorg.xbacklight xfce.xfce4-power-manager
    brightnessctl imagemagick exa
    gcc deadd-notification-center 
    nodePackages.pyright nodePackages.vscode-html-languageserver-bin zoom-us linuxPackages.cpupower
    powertop inetutils nmap cpufetch
    dmenu cmatrix qutebrowser neovim
    libreoffice nodePackages.create-react-app nodejs yarn nodePackages.react-tools
    ranger xorg.xmodmap  powershell gimp
    brave thinkfan bpytop bat polybar lolcat ncdu lm_sensors
    rnix-lsp gnome.gnome-sound-recorder tmux ps_mem taffybar
    noto-fonts ntfs3g gparted file appimage-run woeusb cachix
    feh cinnamon.nemo libva-utils speedtest-cli pass surf gnumake
    river clang-tools ed materia-theme  
    discord waybar swaybg pkg-config
    kitty sway-contrib.grimshot wofi
    dunst networkmanagerapplet tree dwmblocks conky
    ciscoPacketTracer8
    onefetch
    ripgrep 
    # batdistrack 
    # some xfce apps
    xfce.xfce4-clipman-plugin xfce.thunar xfce.xfce4-taskmanager
    ferdi
    # autoconf automake inkscape gdk-pixbuf sassc pkgconfig
    # emacsPgtkGcc
    #rust home-manager metasploit theharvester
    cargo carnix
    # python stuff
    python39
    # python39Packages.numpy python39Packages.pandas
  #     ((emacsPackagesFor emacsPgtkGcc).emacsWithPackages
  #       (epkgs: [
  #         epkgs.vterm]))
   ];
  # virtualbox
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "drishal" ];
  # virtualisation.virtualbox.host.enableExtensionPack = true;
  # virt manager
  programs.dconf.enable = true;
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
    };
  };
  # emacsGcc
  #  programs.emacs = {
  #    enable = true;
  #    package = pkgs.emacsGcc;
  #    extraPackages = (epkgs: [ epkgs.vterm ] );
  #};
  # services.emacs.package = pkgs.emacsUnstable;
  # emacsWithPackages = (pkgs.emacsPackagesGen pkgs.emacsGcc).emacsWithPackages (epkgs: ([epkgs.vterm]));
  #  services.emacs.enable = true;

  # mouse config
  services.xserver.libinput = {
    enable = true;
    # disable mouse acceleration
    #mouse.accelProfile = "flat";
    # mouse.accelSpeed = "0.5";
    touchpad.accelSpeed = "0.4";
    mouse.middleEmulation = false;
  };#

  services.gvfs.enable = true;

  # overlays

  nixpkgs.overlays = [
    #suckless overlays
    (final: prev: {
      dwm = prev.dwm.overrideAttrs (old: { src = ../suckless/dwm-6.3 ;});
      dwmblocks = prev.dwmblocks.override (old: {
        # src = ../suckless/dwmblocks
        conf =../suckless/dwmblocks/blocks.def.h;});
    })

    # dwmblocks 
#    (self: super: {
#      dwmblocks = super.callPackage ./packages/dwmblocks/dwmblocks.nix {};
#      conf = ../suckless/dwmblocks/blocks.def.h;
#    })
#
    # river desktop session
     (final: prev: {
       inherit (prev) callPackage fetchFromGitHub;
     
       river = let
         riverSession = ''
       [Desktop Entry]
       Name=River
       Comment=Dynamic Wayland compositor
       Exec=river
       Type=Application
     '';
       in
         prev.river.overrideAttrs (prevAttrs: rec {
           postInstall = ''
         mkdir -p $out/share/wayland-sessions
         echo "${riverSession}" > $out/share/wayland-sessions/river.desktop
       '';
           passthru.providedSessions = ["river"];
         });
     })

    # xmonad 
#    (final: prev: {
#      haskellPackages = prev.haskellPackages.override (old: {
#        overrides = self: super: {
#          xmonad = prev.haskellPackages.xmonad_0_17_0;
#          xmonad-contrib = prev.haskellPackages.xmonad-contrib_0_17_0;
#          xmonad-extras = prev.haskellPackages.xmonad-extras_0_17_0;
#        };
#      });
#    })
#
    # batdistrack
    # (self: super: {
    #   batdistrack = super.callPackage ./packages/batdistrack/default.nix {};
    # })
    # # (final: prev: {
    #   picom = prev.picom.overrideAttrs (old: { src = /home/drishal/Desktop/git-stuff/picom;});
    # })

    # (self: super: {
    #   discord = super.discord.overrideAttrs (_:{
    #    builtins.fetchTarball { src="https://discord.com/api/download?platform=linux&format=tar.gz"; sha256 = lib.fakeSha256;};
    # });
    #})
    # picom
    (self: super:
      {
        picom = super.picom.overrideAttrs (_: {
          src = builtins.fetchTarball {
            url = https://github.com/yshui/picom/archive/refs/heads/next.zip;
            #sha256 = lib.fakeSha256;
            # sha256 = "0g8k1krxryy9il2347z1gqv6bgg94galzzw0b90prr5q7cnvvgk1";
            sha256 = "sha256:0lh3p3lkafkb2f0vqd5d99xr4wi47sgb57x65wa2cika8pz5sikv";
          };
        });
      })

    # (self: super:
    #   {
    #     river = super.river.overrideAttrs (_: {

    #     });
    #   })



#    (self: super:
#      {
#        discord = super.discord.overrideAttrs (_: {
#          src = builtins.fetchTarball {
#            url = https://discord.com/api/download?platform=linux&format=tar.gz;
#            # sha256="sha256:0hdgif8jpp5pz2c8lxas88ix7mywghdf9c9fn95n0dwf8g1c1xbb";
#	    sha256="sha256:05s7irhw984slalnf7q5rps9i8izq542lnman9s1x6csd26r157s";
#	    # sha256=lib.fakeSha256;
#          };
#        });
#      })      


  ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}


# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs,lib ,... }:

{
  imports =
    [ # Include the results of the hardware scan.
	./hardware-configuration.nix
      # import cachix.nix
      # (import "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos")
      #<home-manager/nixos>
      #./cachix.nix 
    ];

  # kernel parameters
  boot.kernelParams = ["usbcore.autosuspend=-1 iommu=pt "];

  # microde
  hardware.cpu.amd.updateMicrocode = true;
  
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "nixos"; # Define your hostname.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # firmware updator
  services.fwupd.enable = true;
  # cpu governor 
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor="schedutil";
  # open cl 
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  #Vulkan
  hardware.opengl.driSupport = true;
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
   '';
  # non-free stuff
  nixpkgs.config.allowUnfree = true;
  hardware.enableRedistributableFirmware=true;

  #optimizing storage in nixos
  nix.autoOptimiseStore = true;
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
  programs.zsh.enable = true;

  # kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable the Desktop Environment/Window managers.
  services.xserver.enable = true;
  # services.xserver.displayManager.lightdm.enable = true;
  #services.xserver.windowManager.qtile.enable = true;
  services.xserver.windowManager.xmonad.enable = true;
  services.xserver.windowManager.xmonad.enableContribAndExtras=true;
  # services.xserver.windowManager.awesome.enable = true;
  # services.xserver.windowManager.xmonad.extraPackages=true;
  # services.xserver.windowManager.dwm.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  # services.xserver.desktopManager.xfce.enable = true;
  # services.xserver.desktopManager.lxqt.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  services.gnome.tracker.enable = false;
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

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  # some pulseaudio settings
  hardware.pulseaudio.extraConfig =  "load-module module-suspend-on-idle";

  # backlight 
  hardware.acpilight.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.drishal = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel"  "network" "video"]; # Enable ‘sudo’ for the user.
  };

  #jaba 
  programs.java = { enable = true ; };

  # nm-applet
  programs.nm-applet.enable=true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim haskellPackages.xmobar
    alacritty xorg.xkill git
    man kitty teams
    papirus-icon-theme xorg.xf86videoamdgpu lxappearance
    lxsession libnotify xclip starship
    cmake volumeicon usbutils
    pavucontrol killall htop
    firefox neofetch steam-run discord
    picom inxi hack-font xarchiver unzip
    nitrogen rofi trayer arc-theme
    xfce.xfce4-clipman-plugin youtube-dl
    xfce.xfce4-notifyd mpv smplayer pfetch
    qbittorrent  mesa-demos glxinfo
    xorg.xdpyinfo evince qt5ct
    redshift xorg.xbacklight xfce.xfce4-power-manager
    brightnessctl imagemagick exa
    gcc deadd-notification-center tdesktop
    nodePackages.pyright nodePackages.vscode-html-languageserver-bin zoom-us linuxPackages.cpupower
    powertop  telnet nmap cpufetch
    dmenu dwmblocks cmatrix qutebrowser neovim
    libreoffice nodePackages.create-react-app nodejs yarn nodePackages.react-tools
    ranger xorg.xmodmap  powershell gimp
    brave thinkfan bpytop bat polybar lolcat ncdu lm_sensors
    rnix-lsp gnome.gnome-sound-recorder tmux ps_mem taffybar
    noto-fonts ntfs3g gparted file appimage-run etcher woeusb 
    #rust home-manager metasploit theharvester 
    cargo carnix
    # python stuff
    python39
    # python39Packages.numpy python39Packages.pandas
    # ((emacsPackagesNgGen emacsPgtkGcc).emacsWithPackages 
    #   (epkgs: [
    #     epkgs.vterm]))
  ];
  # virtualbox
  #virtualisation.virtualbox.host.enable = true;
  #users.extraGroups.vboxusers.members = [ "drishal" ];
  #virtualisation.virtualbox.host.enableExtensionPack = true;

  virtualisation = {
    libvirtd = {
      enable = true;
      qemuOvmf = true;
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
    # enable = true;
    # disable mouse acceleration
    #mouse.accelProfile = "flat";
    #mouse.accelSpeed = "0";
    mouse.middleEmulation = false;
  };#

  # overlays

  nixpkgs.overlays = [
    # (final: prev: {
    #   dwm = prev.dwm.overrideAttrs (old: { src = /home/drishal/Desktop/suckless/dwm-6.2 ;});
    # })
    # #(final: prev: {
    # #  dwmblocks = prev.dwmblocks.overrideAttrs (old: { src = /home/drishal/Desktop/suckless/dwmblocks ;});
    # #})
    # (final: prev: {
    #   dmenu = prev.dmenu.overrideAttrs (old: { src = /home/drishal/Desktop/suckless/dmenu ;});
    # })
    

    # (final: prev: {
    #   picom = prev.picom.overrideAttrs (old: { src = /home/drishal/Desktop/git-stuff/picom;});
    # })

    # (self: super: {
    #   discord = super.discord.overrideAttrs (_:{
    #    builtins.fetchTarball { src="https://discord.com/api/download?platform=linux&format=tar.gz"; sha256 = lib.fakeSha256;};
    # });
    #})
    #  (final: prev: {
    #   qtile = prev.qtile.overrideAttrs (old: { 
    #		   src = /home/drishal/git-stuff/qtile; 
    #		   patches=[/home/drishal/git-stuff/qtile/patches-for-nix/0001-Substitution-vars-for-absolute-paths.patch /home/drishal/git-stuff/qtile/patches-for-nix/0002-Restore-PATH-and-PYTHONPATH.patch /home/drishal/git-stuff/qtile/patches-for-nix/0003-Restart-executable.patch ] ;});})

    # (import (builtins.fetchTarball {
    #   url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
    # }))
    #(self: super: { discord = super.discord.overrideAttrs (_: { src = builtins.fetchTarball https://discord.com/api/download?platform=linux&format=tar.gz; sha256 = lib.fakeSha256;});})
    #(self: super: { discord = super.discord.overrideAttrs (_: builtins.fetchTarball { url = https://discord.com/api/download?platform=linux&format=tar.gz; sha256 = "1ahj4bhdfd58jcqh54qcgafljqxl1747fqqwxhknqlasa83li75n";});})
(self: super:
  {
    discord = super.discord.overrideAttrs (_: {
      src = builtins.fetchTarball {
        url = https://discord.com/api/download?platform=linux&format=tar.gz;
	#sha256 = lib.fakeSha256;
        sha256 = "1ahj4bhdfd58jcqh54qcgafljqxl1747fqqwxhknqlasa83li75n";
      };
    });
  })
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


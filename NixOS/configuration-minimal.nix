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
   '';
  # non-free stuff
  nixpkgs.config.allowUnfree = true;
  hardware.enableRedistributableFirmware=true;

  #optimizing storage in nixos
  # nix.autoOptimiseStore = true;
  nix.settings.auto-optimise-store = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };
  # zsh
  # programs.zsh.enable = true;

  # kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable the Desktop Environment/Window managers.
  services.xserver = {
    enable = true;

    desktopManager = {
      plasma5.enable = true;
    };
    displayManager.sddm.enable = true;
  };
  # fprint
  # services.fprintd.enable = true;
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

  # Enable sound.
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    wireplumber.enable = true;
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
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
  systemd.packages = with pkgs; [
    # batdistrack
  ];
  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.drishal = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel"  "network" "video"  "-manager" "docker"]; # Enable ‘sudo’ for the user.
  };

  # nm-applet
  programs.nm-applet.enable=true;

  environment.systemPackages = with pkgs; [
    wget vim haskellPackages.xmobar
    alacritty xorg.xkill git
    man teams batdistrack
    papirus-icon-theme xorg.xf86videoamdgpu lxappearance
    lxsession libnotify xclip starship
    cmake volumeicon usbutils
    pavucontrol killall htop
    firefox neofetch steam-run 
    picom inxi  xarchiver unzip
    nitrogen rofi trayer arc-theme
    youtube-dl
     mpv smplayer pfetch
    qbittorrent  mesa-demos glxinfo
    xorg.xdpyinfo evince qt5ct
    redshift xorg.xbacklight xfce.xfce4-power-manager
    brightnessctl imagemagick exa
    gcc deadd-notification-center 
    linuxPackages.cpupower
    powertop inetutils nmap cpufetch
    dmenu dwmblocks cmatrix qutebrowser neovim
    feh cinnamon.nemo libva-utils speedtest-cli pass
    surf gnumake
    python39
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
  # mouse config
  services.xserver.libinput = {
    enable = true;
    touchpad.accelSpeed = "0.4";
    mouse.middleEmulation = false;
  };
  system.stateVersion = "21.05"; 

}

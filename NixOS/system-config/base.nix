{ config, pkgs, inputs, lib, ... }:

# base system configuration
{
  # boot.kernelPackages = pkgs.linuxPackages_xanmod_latest; # alternative: linuxPackages_latest pkgs.linuxPackages_zen
  boot.kernelPackages = pkgs.linuxPackages_latest; # alternative: linuxPackages_latest pkgs.linuxPackages_zen

  # kernel parameters
  boot.kernelParams = [ "mitigations=off" "clearcpuid=514" ];

  # microde
  hardware.cpu.amd.updateMicrocode = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # systemd settings 
  systemd.extraConfig = ''
  DefaultTimeoutStopSec=10s
'';
  #bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.package = pkgs.bluez;
  services.blueman.enable = true;


  # firmware updator
  services.fwupd.enable = true;

  #man
  # documentation.man.generateCaches = false;

  #openssh
  services.openssh = {
    enable = true;
    ports = [22];
  };

  # power-management
  powerManagement =
    {
      enable = true;
      cpuFreqGovernor = "schedutil";
    };
  services.power-profiles-daemon.enable=true;
  services.acpid.enable=true;

  hardware.opengl =
    {
      extraPackages = with pkgs; [
        rocm-opencl-icd
        rocm-opencl-runtime
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
      driSupport = true;
      driSupport32Bit = true;
    };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Networking
  # services.resolved = {
    # enable=true;
  # }
  networking = {
    networkmanager = {
      enable = true;
      # dns = "systemd-resolved";
      wifi.macAddress = "random";
    };
    wireless.iwd.enable = true;
    # hostname
    hostName = "nixos";
    # dns
    nameservers = [
      # cloudflare
      # "45.90.28.182"
      # "45.90.30.182"
      "1.1.1.1"
      "2606:4700:4700::1111"

      #  google
      # "8.8.8.8"
      # "2001:4860:4860::8888"
    ];
    extraHosts = "185.199.108.133 raw.githubusercontent.com";  
  };
  # Configure keymap in X11
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # services.logind.lidSwitch = "suspend"; 
  # Enable sound.
  sound.enable = true;

  #postgresql
  services.postgresql = {
    enable = false;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE drishal WITH LOGIN PASSWORD 'catuserbot' CREATEDB;
      CREATE DATABASE catuserbot;
      GRANT ALL PRIVILEGES ON DATABASE catuserbot TO drishal;
    '';
  };

  # services.mysql = {
  #   enable=true;
  #   package=pkgs.mariadb;
  # };

  # mongodb
  # services.mongodb.enable = true;

  services.smartd.enable = true;

  security.rtkit.enable = true;

  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
  services.pipewire = {
    wireplumber.enable = true;
    # media-session.enable = false;
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
  };
  hardware.pulseaudio.enable = false;
  # backlight
  hardware.acpilight.enable = true;
}

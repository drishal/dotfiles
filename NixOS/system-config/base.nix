{ config, pkgs, inputs, lib, ... }:

# base system configuration
{
  boot.kernelPackages = pkgs.linuxPackages_latest; # alternative: linuxPackages_latest
  #  pulling kernel from master
  # boot.kernelPackages =  inputs.nixpkgs-master.legacyPackages.${pkgs.system}.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest.override {
  #   argsOverride = rec {
  #     src = pkgs.fetchurl {
  #       url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${version}.tar.xz";
  #       sha256 = "sha256-bjzVbug6nLWsP94UQsQDZ6tnNolGxMk7vrHGVmSg08U=";
  #     };
  #     version = "5.17.4";
  #     modDirVersion = "5.17.4";
  #     extraConfig = ''
  #       X86_AMD_PSTATE y
  #     '';
  #     extraMakeFlags = let lsmod = ./kernel/lsmod.txt; in ["LSMOD=${lsmod}" "localmodconfig"];

  #   };
  # });

  # kernel parameters
  boot.kernelParams = [ "iommu=pt" ];

  # microde
  hardware.cpu.amd.updateMicrocode = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";


  #bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.package = pkgs.bluezFull;
  services.blueman.enable = true;


  # firmware updator
  services.fwupd.enable = true;

  powerManagement =
    {
      enable = true;
      cpuFreqGovernor = "schedutil";
    };

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
    };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Networking
  networking = {
    networkmanager.enable = true;
    wireless.iwd.enable = true;
    # hostname
    hostName = "nixos";
    # dns
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };
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
    wireplumber.enable = false;
    media-session.enable = true;
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

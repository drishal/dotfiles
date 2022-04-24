{ config, pkgs, inputs, lib, ... }:

# base system configuration
{
  boot.kernelPackages = pkgs.linuxPackages_latest; # alternative: linuxPackages_latest

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

  # Define your hostname.
  networking.hostName = "nixos";

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
      ];
      driSupport = true;
    };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

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

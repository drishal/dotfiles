{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

# base system configuration
{
  # boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  # boot.kernelPackages = pkgs.linuxPackages_6_11;
  # services.scx = {
  #   enable = true;
  #   scheduler = "scx_bpfland";
  #   package = pkgs.scx.full;
  # };
  # by default uses rustland
  # systemd.services.scx.serviceConfig.Restart = lib.mkForce "always";
  # boot.kernelPackages = pkgs.linuxPackages_testing;

  # kernel parameters
  boot.kernelParams = [
    "mitigations=off"
    "clearcpuid=514"
    "i8042.probe_defer"
    "split_lock_detect=off"
  ];
  #"processor.max_cstate=1" "intel_idle.max_cstate=0"
  # microde
  hardware.cpu.amd.updateMicrocode = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";
  services.ntp.enable = true;
  services.timesyncd.enable = true;

  # systemd settings
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  # cgroups support
  # systemd.enableUnifiedCgroupHierarchy = true;
  #bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # firmware updator
  services.fwupd.enable = true;

  #man
  # documentation.man.generateCaches = false;

  #openssh
  services.openssh = {
    enable = true;
    ports = [
      22
      8022
    ];
  };

  networking.firewall.allowedTCPPorts = [
    22
    8022
    8000
  ];
  # power-management
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "schedutil";
  };
  services.power-profiles-daemon.enable = true;
  services.acpid.enable = true;
  # services.auto-cpufreq =
  #   {
  #     enable=true;
  #     settings = {
  #       charger = {
  #         governor = "performance";
  #         turbo = "always";
  #       };
  #       battery={
  #         governor = "schedutil";
  #         turbo = "auto";
  #       };
  #     };
  #   };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Networking
  #openvpn
  # programs.openvpn3.enable = true;
  # services.resolved = {
  #   enable = true;
  #   dnssec = "true";
  #   domains = [ "~." ];
  #   fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
  #   extraConfig = ''
  #   DNSOverTLS=yes
  #   '';
  # };
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      # dns = "systemd-resolved";
      wifi.macAddress = "random";
    };
    # wireless.enable = true;
    # wireless.iwd.enable = true;
    # hostname
    #hostName = "nixos";
    # dns
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    extraHosts = "185.199.108.133 raw.githubusercontent.com";
    # nameservers= [
    # cloudflare
    # "45.90.28.182"
    # "45.90.30.182"
    # "1.1.1.1"
    # "2606:4700:4700::1111"

    #  google
    # "8.8.8.8"
    # "2001:4860:4860::8888"
    # ];
  };
  # Configure keymap in X11
  # services.xserver.layout = "us";
  services.xserver.xkb.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    # drivers = with pkgs; [foomatic-db-ppds-withNonfreeDb];
  };
  services.avahi = {
    enable = true;
    nssmdns = true;
    openFirewall = true;
  };

  # services.logind.lidSwitch = "suspend";
  # Enable sound.
  # sound.enable = true;

  #postgresql
  # services.postgresql = {
  #   enable = false;
  #   enableTCPIP = true;
  #   authentication = pkgs.lib.mkOverride 10 ''
  #     local all all trust
  #     host all all 127.0.0.1/32 trust
  #     host all all ::1/128 trust
  #   '';
  #   initialScript = pkgs.writeText "backend-initScript" ''
  #     CREATE ROLE drishal WITH LOGIN PASSWORD 'catuserbot' CREATEDB;
  #     CREATE DATABASE catuserbot;
  #     GRANT ALL PRIVILEGES ON DATABASE catuserbot TO drishal;
  #   '';
  # };

  # services.mysql = {
  #   enable=true;
  #   package=pkgs.mariadb;
  # };

  # mongodb
  # services.mongodb.enable = true;

  services.smartd.enable = true;

  services.haveged.enable = true;

  security.rtkit.enable = true;

  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
  services.pipewire = {
    wireplumber = {
      enable = true;
      extraConfig = {
        actions = {
          update-props = {
            "bluez5.autoswitch-profile" = true;
          };
        };
      };
    };
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

  # udev 250 doesn't reliably reinitialize devices after restart
  systemd.services.systemd-udevd.restartIfChanged = false;

  #session variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  networking.firewall.enable = false;
}

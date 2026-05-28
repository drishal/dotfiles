{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

# base system configuration
{
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_zen;
  # boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-zen4;
  systemd.user.services.orca.wantedBy = lib.mkForce [];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # common kernel params (host-specific params live in hosts/<host>/default.nix
  # and hosts/common/cpu/*.nix)
  boot.kernelParams = [
    "split_lock_detect=off"
    "preempt=full"
    "nowatchdog"
  ];

  # network / watchdog sysctls only — memory tunables live in hosts/common/memory.nix
  boot.kernel.sysctl = {
    "net.ipv4.tcp_fastopen" = 3;
    "net.core.somaxconn" = 8192;
    "net.core.netdev_max_backlog" = 8192;
    "kernel.nmi_watchdog" = 0;
    "kernel.watchdog" = 0;
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";
  # services.ntp.enable = true;
  services.timesyncd.enable = true;

  # systemd settings
  # systemd.extraConfig = ''
  #   DefaultTimeoutStopSec=10s
  # '';

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

  # power-management
  powerManagement = {
    enable = true;
    # cpuFreqGovernor = "schedutil";
  };
  # services.power-profiles-daemon.enable = true;
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
    nssmdns4 = true;
  };

  services.logind.killUserProcesses = true;
  # services.logind.lidSwitch = "suspend";
  # Enable sound.
  # sound.enable = true;
  # # services.mysql = {
  #   enable=true;
  #   package=pkgs.mariadb;
  # };

  # mongodb
  # services.mongodb.enable = true;

  services.smartd.enable = true;

  # services.haveged.enable = true;  # obsolete on kernel 5.6+ (CRNG self-seeds)

  security.rtkit.enable = true;

  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
  services.tailscale = {
    enable = true;
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
        pipewire = {
            "10-fifine-mic" = {
              match = [
                { "node.name" = "alsa_input.usb-3142_Fifine_Microphone-00.mono-fallback"; }
              ];
              update-props = {
                "audio.format" = "S16LE";
                "audio.rate" = 48000;  # Force mic to 48 kHz only
                "audio.channels" = 1; # Keep mono
                "channelmix.upmix" = false;
                "channelmix.normalize" = false;
              };
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
  services.pulseaudio.enable = false;
  # backlight
  hardware.acpilight.enable = true;

  # udev 250 doesn't reliably reinitialize devices after restart
  systemd.services.systemd-udevd.restartIfChanged = false;

  #session variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    LESS = "-g -i -M -R -S -w -X -z4";
  };

  networking.firewall.enable = false;
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="373b", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="10c9", MODE="0666", GROUP="plugdev", TAG+="uaccess"
  '';

}

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

# base system configuration
{
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  systemd.user.services.orca.wantedBy = lib.mkForce [ ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # common kernel params (host-specific params live in hosts/<host>/default.nix
  # and hosts/common/cpu/*.nix)
  boot.kernelParams = [
    "split_lock_detect=off"
    "preempt=full"
    "nowatchdog"
  ];

  # network / watchdog / inotify sysctls — memory tunables live in hosts/common/memory.nix
  boot.kernel.sysctl = {
    "net.ipv4.tcp_fastopen" = 3;
    "net.core.somaxconn" = 8192;
    "net.core.netdev_max_backlog" = 8192;
    "kernel.nmi_watchdog" = 0;
    "kernel.watchdog" = 0;
    "fs.inotify.max_user_watches" = 1048576; # 1M — desktop/gaming workloads exhaust the default 524288
    "fs.inotify.max_user_instances" = 1024; # default 128; quickshell alone opens 14
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
  systemd.settings.Manager.DefaultTimeoutStopSec = "30s";

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

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      dns = "systemd-resolved";
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
  # Local DNS cache (resolved). With Tailscale DNS enabled (CorpDNS) the real
  # upstream is whatever the tailnet pushes — currently NextDNS over DoH via the
  # 100.100.100.100 MagicDNS stub, NOT the Cloudflare servers below (those are only
  # the fallback resolved uses when Tailscale DNS is off). resolved caches in front
  # of that path so repeat lookups skip the network round-trip, and gives Tailscale
  # the split-DNS integration it prefers (MagicDNS for *.ts.net, system DNS for the
  # rest) instead of rewriting resolv.conf directly. Opportunistic DoT only applies
  # to resolved's own direct upstreams (the fallback path) and degrades to plaintext
  # if unavailable. DNSSEC off to avoid breaking captive portals.
  services.resolved = {
    enable = true;
    dnssec = "false";
    dnsovertls = "opportunistic";
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
              "audio.rate" = 48000; # Force mic to 48 kHz only
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

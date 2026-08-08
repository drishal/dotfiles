{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

# base system configuration
{
  boot.kernelPackages = pkgs.linuxPackages_cachyos-gcc ;
  systemd.user.services.orca.wantedBy = lib.mkForce [ ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # host-specific params live in hosts/<host>/default.nix and hosts/common/cpu/*.nix
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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.efi.efiSysMountPoint = "/boot/efi";

  time.timeZone = "Asia/Kolkata";
  # services.ntp.enable = true;
  services.timesyncd.enable = true;

  systemd.settings.Manager.DefaultTimeoutStopSec = "30s";

  # cgroups support
  # systemd.enableUnifiedCgroupHierarchy = true;
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services.fwupd.enable = true;

  #man
  # documentation.man.generateCaches = false;

  services.openssh = {
    enable = true;
    ports = [
      22
      8022
    ];
  };

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
  # services.xserver.layout = "us";
  services.xserver.xkb.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

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

  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
  # Local DNS cache giving Tailscale the split-DNS integration it prefers; with
  # tailnet DNS on, upstream is MagicDNS, not the nameservers above. DNSSEC off for captive portals.
  services.resolved = {
    enable = true;
    dnssec = "false";
    dnsovertls = "opportunistic";
  };
  services.tailscale = {
    enable = true;
  };
  hardware.acpilight.enable = true;

  # udev 250 doesn't reliably reinitialize devices after restart
  systemd.services.systemd-udevd.restartIfChanged = false;

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

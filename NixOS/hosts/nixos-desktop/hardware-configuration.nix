{
  config,
  lib,
  pkgs,
  modulesPath,
  user,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelParams = [
    "amdgpu.aspm=0" # PCIe ASPM off — desktop latency
    "processor.max_cstate=2" # C2 cap; scx_lavd C3 wake was ~350µs
    # khugepaged collapse locks pages; pairs with compaction_proactiveness=0
    "transparent_hugepage=madvise"
    "iommu=pt"
    "threadirqs"
    "mitigations=off"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/dfe9f586-6ff5-4ec8-a459-e665323919dc";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/AA53-4C0A";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];

  networking.hostName = "nixos-desktop";
  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  #networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp11s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp12s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  services.hardware = {
    openrgb = {
      enable = true;
      motherboard = "amd";
      package = pkgs.openrgb-with-all-plugins;
    };
  };

  users.groups.i2c.members = [ user ];
  # services.sunshine = {
  #   enable = true;
  #   autoStart = false;
  #   capSysAdmin = true;
  #   openFirewall = true;
  # };

  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 80;
  };

}

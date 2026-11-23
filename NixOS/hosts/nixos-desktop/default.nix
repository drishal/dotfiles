{ inputs, lib, pkgs, ... }:
{
  imports = [
    ../common
    inputs.brave-previews.nixosModules.default
    ../common/memory.nix
    ../common/storage.nix
    ../common/network-tuning.nix
    ../common/cpu/amd-pstate.nix
    ../common/scheduler/lavd.nix
    ../common/graphics/amd.nix
    ./hardware-configuration.nix
    ./packages.nix
    ../common/jellyfin.nix
  ];

  # Ryzen 9 7900X is Zen 4: Clang ThinLTO + AutoFDO with _processor_opt=ZEN4 (-march=znver4).
  # Kernel + module tree come from nyx-cache; v4l2loopback/openrazer are not cached there and
  # build locally in ~1 min. Per-host on purpose: nixos-work is Intel and shares ../common.
  boot.kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4;

  # card/renderD numbering swaps across boots, so name the RX 6800 by PCI slot.
  # No colons in the symlinks: AQ_DRM_DEVICES is a ':'-separated list.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:03:00.0", SYMLINK+="dri/rx6800"
    SUBSYSTEM=="drm", KERNEL=="renderD*", KERNELS=="0000:03:00.0", SYMLINK+="dri/rx6800-render"
  '';

  environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/rx6800";

  # firmware boots the UEFI console at 1920x1080; the 4K Acer shows it 1:1 in a corner
  boot.loader.systemd-boot.consoleMode = "max";

  # Override common/jellyfin.nix's renderD128, which lands on the iGPU some boots.
  services.jellyfin.hardwareAcceleration.device = lib.mkForce "/dev/dri/rx6800-render";

  # nm-online -s waits for NM startup, not connectivity, and cost 7.6s of the
  # 18.9s userspace boot via network-online.target -> docker -> graphical.target.
  # Nothing wanting that target here (docker, jellyfin, fwupd-refresh) needs
  # upstream connectivity to start.
  systemd.services.NetworkManager-wait-online.enable = false;
}

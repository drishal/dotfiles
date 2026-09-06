{ inputs, lib, ... }:
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

  # card/renderD numbering swaps across boots, so name the RX 6800 by PCI slot.
  # No colons in the symlinks: AQ_DRM_DEVICES is a ':'-separated list.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:03:00.0", SYMLINK+="dri/rx6800"
    SUBSYSTEM=="drm", KERNEL=="renderD*", KERNELS=="0000:03:00.0", SYMLINK+="dri/rx6800-render"
  '';

  environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/rx6800";

  # Override common/jellyfin.nix's renderD128, which lands on the iGPU some boots.
  services.jellyfin.hardwareAcceleration.device = lib.mkForce "/dev/dri/rx6800-render";
}

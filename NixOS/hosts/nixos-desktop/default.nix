{ inputs, ... }:
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

  # Pin Hyprland/Aquamarine to the RX 6800; card0/card1 swap across boots.
  environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/by-path/pci-0000:03:00.0-card";
}

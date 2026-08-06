{ inputs, ... }:
{
  imports = [
    ../common
    inputs.brave-previews.nixosModules.default
    ../common/memory.nix
    ../common/storage.nix
    ../common/network-tuning.nix
    ../common/cpu/intel-pstate.nix
    ../common/scheduler/bpfland.nix
    ../common/graphics/nvidia.nix
    ./hardware-configuration.nix
    ./mounts.nix
    ./packages.nix
    ./virtualisation.nix
  ];
}

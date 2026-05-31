{ ... }:
{
  imports = [
    ../common
    ../common/memory.nix
    ../common/storage.nix
    ../common/cpu/amd-pstate.nix
    ../common/scheduler/lavd.nix
    ../common/graphics/amd.nix
    ./hardware-configuration.nix
    ./packages.nix
    ../common/jellyfin.nix
  ];
}

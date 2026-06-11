{ ... }:
# Template / baseline host. Copy this folder to bootstrap a new machine.
{
  imports = [
    ../common
    ../common/memory.nix
    ../common/storage.nix
    ../common/network-tuning.nix
    ../common/graphics/amd.nix
    ./hardware-configuration.nix
  ];
}

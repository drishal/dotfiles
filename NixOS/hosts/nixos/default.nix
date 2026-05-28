{ ... }:
# Template / baseline host. Copy this folder to bootstrap a new machine.
{
  imports = [
    ../common
    ../common/memory.nix
    ../common/storage.nix
    ./hardware-configuration.nix
  ];
}

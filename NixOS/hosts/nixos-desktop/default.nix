{ ... }:
{
  imports = [
    ../common
    ../common/memory.nix
    ../common/storage.nix
    ../common/cpu/amd-pstate.nix
    ../common/scheduler/lavd.nix
    ./hardware-configuration.nix
  ];

  # Personal desktop — accept the risk for raw perf
  boot.kernelParams = [ "mitigations=off" ];

  programs.gamemode.enable = true;
}

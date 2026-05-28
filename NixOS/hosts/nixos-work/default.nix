{ ... }:
{
  imports = [
    ../common
    ../common/memory.nix
    ../common/storage.nix
    ../common/cpu/intel-pstate.nix
    ../common/scheduler/bpfland.nix
    ./hardware-configuration.nix
  ];

  # Work machine — keep CPU mitigations ON (Cascade Lake has MDS/L1TF/Zombieload).
  # T400 is a discrete workstation card (no PRIME offload), so the nvidia
  # powerManagement defaults from hosts/common/graphics/nvidia.nix are correct.
}

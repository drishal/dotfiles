{ ... }:
# Zen 4+ on kernel >= 6.3. Lets the firmware do per-µs frequency decisions.
{
  boot.kernelParams = [ "amd_pstate=active" ];
  powerManagement.cpuFreqGovernor = "performance";
  hardware.cpu.amd.updateMicrocode = true;
}

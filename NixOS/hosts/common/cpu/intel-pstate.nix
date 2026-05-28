{ ... }:
# Skylake+ (incl. Cascade Lake-W). HWP-driven performance scaling.
{
  boot.kernelParams = [ "intel_pstate=active" ];
  powerManagement.cpuFreqGovernor = "performance";
  hardware.cpu.intel.updateMicrocode = true;
}

{ ... }:
# Memory tuning — large RAM + zram + NVMe. Absolute byte values instead of percent
# ratios: on 64+GB the default ratios grow writeback queues into stall territory.
{
  # zram is the swap device; zswap would compress the same pages twice
  boot.kernelParams = [ "zswap.enabled=0" ];

  boot.kernel.sysctl = {
    "vm.dirty_bytes" = 4 * 1024 * 1024 * 1024;       # 4 GiB hard cap
    "vm.dirty_background_bytes" = 64 * 1024 * 1024;  # 64 MiB starts writeback
    "vm.swappiness" = 10;                             # 64GB; only use zram under real pressure
    "vm.compaction_proactiveness" = 0;                # no proactive compaction stalls
    "vm.page-cluster" = 0;                            # zram is RAM, no readahead
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # systemd-oomd is on by default but monitors nothing — every slice ships
  # ManagedOOM*=auto. Opt in the root + user slices (Fedora's set).
  systemd.oomd = {
    enableRootSlice = true;
    enableUserSlices = true;
    settings.OOM.DefaultMemoryPressureDurationSec = "20s"; # PSI stall time; no per-slice equivalent
  };
}

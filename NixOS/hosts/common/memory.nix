{ ... }:
# Memory tuning — large RAM + zram + NVMe.
# Using absolute byte values instead of percent ratios; on 64+GB systems the
# default ratios let writeback queues grow into multi-GB territory and stall
# the system when they flush.
{
  boot.kernel.sysctl = {
    "vm.dirty_bytes" = 4 * 1024 * 1024 * 1024;       # 4 GiB hard cap
    "vm.dirty_background_bytes" = 64 * 1024 * 1024;  # 64 MiB starts writeback
    "vm.swappiness" = 40;                             # zram is cheap, prefer compression
    "vm.compaction_proactiveness" = 0;                # no proactive compaction stalls
    "vm.page-cluster" = 0;                            # zram is RAM, no readahead
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };
}

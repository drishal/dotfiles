{ pkgs, ... }:
# Latency-criticality aware virtual deadline — designed for gaming workloads.
# Higher framerates than EEVDF with fewer stutters; Core Compaction saves
# power at <50% CPU load.
{
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ "--performance" ];
    package = pkgs.scx.full;
  };
}

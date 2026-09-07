{ pkgs, ... }:
# Cache-aware locality scheduler. Better for many-core throughput workloads
# (e.g. Xeon W with 36 threads) than gaming-tuned schedulers.
{
  services.scx = {
    enable = true;
    scheduler = "scx_bpfland";
    # defaults: homogeneous single-socket CPU needs no primary-domain hint;
    # -p (per-CPU priority) trades priority-inversion risk for little gain
    extraArgs = [ ];
    package = pkgs.scx.full;
  };
}

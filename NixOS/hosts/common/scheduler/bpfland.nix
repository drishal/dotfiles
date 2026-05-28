{ pkgs, ... }:
# Cache-aware locality scheduler. Better for many-core throughput workloads
# (e.g. Xeon W with 36 threads) than gaming-tuned schedulers.
{
  services.scx = {
    enable = true;
    scheduler = "scx_bpfland";
    extraArgs = [ "-m" "performance" "-p" ];
    package = pkgs.scx.full;
  };
}

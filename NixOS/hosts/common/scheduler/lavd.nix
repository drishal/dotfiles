{ pkgs, ... }:
# LAVD --performance: gaming/audio tail latency. Compaction off (all cores).
{
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ "--performance" ];
    package = pkgs.scx.full;
  };
}

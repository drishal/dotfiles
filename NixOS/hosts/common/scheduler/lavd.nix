{ pkgs, ... }:
# LAVD --performance: gaming/audio tail latency. Compaction off (all cores).
{
  services.scx-loader = {
    enable = true;
    schedsPackages = [ pkgs.scx.full ];
    config = {
      default_sched = "scx_lavd";
      default_mode = "Gaming";
      scheds.scx_lavd.gaming_mode = [ "--performance" ];
    };
  };
}

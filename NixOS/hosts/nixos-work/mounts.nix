{ ... }:
{
  # 1.8 TB ext4 data disk (sda1). Not boot-critical: nofail so a missing or
  # failing disk degrades to "not mounted" instead of hanging boot in the
  # systemd device-wait, and a bounded timeout so that wait can't stall.
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/21733f95-cb4e-41b6-8b81-43e26075fa17";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
      "x-systemd.device-timeout=10s"
    ];
  };
}

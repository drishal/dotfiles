{ ... }:
# Monthly scrub of the topmost subvol only — /, /nix, /home are one filesystem
{
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
}

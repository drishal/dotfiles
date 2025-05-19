{ config, lib, pkgs, ... }:
{

  wayland.windowManager.hyprland.settings = {
    monitor = [",highrr,auto,1, bitdepth, 10"];
    # monitor = [",highrr,auto,1, bitdepth, 10, cm, hdr, sdrbrightness, 1.2, sdrsaturation, 1"];
  };
}

{ config, lib, pkgs, ... }:
{

  wayland.windowManager.hyprland.settings = {
    monitor = [",highrr,auto,1, bitdepth, 10"];
  };
}

{ config, lib, pkgs, ... }:
{

  wayland.windowManager.hyprland.settings = {
    monitor = [",highrr,auto,1, bitdepth, 10"];
    # monitor = [",highrr,auto,1, bitdepth, 10, cm, hdr, sdrbrightness, 1.1, sdrsaturation, 1"];
    # monitorv2 = {
    #   output = "HDMI-A-1";
    #   mode = "1920x1080@144";
    #   position = "0x0";
    #   bitdepth = 10;
    #   supports_hdr = 1;
    #   sdr_min_luminance = 0.005;
    #   sdr_max_luminance = 210;
    # };
  };
}

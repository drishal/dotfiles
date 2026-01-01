{ config, lib, pkgs, ... }:
# {
#   wayland.windowManager.hyprland.settings = {
#     monitor = [",highrr,auto,1, bitdepth, 10"];
#   };
# }
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = [
        "HDMI-A-1,1920x1080@143.98,0x0,1,bitdepth,10,cm,hdr,sdrbrightness,1.13,sdrsaturation,1.0"
      ];
      "render:cm_fs_passthrough" = true;
      "render:cm_sdr_eotf" = 2;
    };
  };
}


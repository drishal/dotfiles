{ config, lib, pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    monitor = [",highrr,auto,1, bitdepth, 10"];
    # monitor = ["HDMI-A-1,1920x1080@144,0x0,1,transform,1"];
  };
}
# {
#   wayland.windowManager.hyprland = {
#     enable = true;
#     settings = {
#       # monitor = [
#       # "HDMI-A-1,1920x1080@143.98,0x0,1,bitdepth,10,cm,hdr,sdrbrightness,1.2,sdrsaturation,1.0"
#       # "HDMI-A-1, 1920x1080@144, 0x0, 1, bitdepth, 10, cm, hdr, sdrbrightness, 1.05, sdrsaturation, 1.00"
#       # ];
#       monitorv2 = [
#         {
#           output = "HDMI-A-1";  # Check 'hyprctl monitors' if this should be DP-1
#           mode = "1920x1080@144";
#           position = "0x0";
#           scale = 1;

#           # --- HDR & Color Pipeline ---
#           bitdepth = 10;
#           cm = "hdr";
          
#           # Enable FreeSync Premium (Critical for this monitor)
#           vrr = 1;

#           # --- SDR Appearance in HDR Mode ---
#           # Adjust sdrbrightness if desktop looks too dim (1.0 - 2.0 range)
#           sdrbrightness = 1.05;
#           sdrsaturation = 1.05; # Slight boost to counter wash-out on sRGB panels

#           # --- Hardware Capabilities (LG 24GN75R Specifics) ---
          
#           # IMPORTANT: This panel is sRGB 99% (not DCI-P3). 
#           # Setting this to 0 (auto) or -1 (off) prevents Hyprland from 
#           # trying to force wide gamut colors that the monitor can't display.
#           supports_wide_color = 0; 
          
#           # Force HDR signal on
#           supports_hdr = 1;

#           # --- Luminance Limits (Nits) ---
#           # LG 24GN75R is typically ~300 nits peak with ~1000:1 contrast.
#           # IPS blacks are roughly 0.3 nits at max brightness.
#           min_luminance = 0.30;
#           max_luminance = 300;
#           max_avg_luminance = 230;

#           # --- SDR Reference Mapping ---
#           # Defines "Paper White" for SDR content. 203 is the ITU standard.
#           sdr_min_luminance = 0.05;
#           sdr_max_luminance = 203;
#         }

#       ];
#       "render:cm_fs_passthrough" = true;
#       "render:cm_sdr_eotf" = 2;
#     };
#   };
# }


{ config, lib, pkgs, ... }:
{
  #   wayland.windowManager.hyprland.settings = {
  #     # monitor = [",highrr,auto,1, bitdepth, 10"];
  #     monitor = [", 3840x2160@160, auto, 2"];

  #     # monitor = ["HDMI-A-1,1920x1080@144,0x0,1,transform,1"];
  #   };
  # }
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

  wayland.windowManager.hyprland.settings = {
    monitor = [
      # 1. Primary Monitor (Acer 4K) - Left
      # Resolution: 4K @ 160Hz | Position: 0x0 | Scale: 1.5 (Recommended for 27" 4K)
      "DP-1, 3840x2160@160, 0x0, 1.5"
      # "DP-1, 1920x1080@320, 0x0, 1"

      # 2. Secondary Monitor (LG) - Right & Vertical
      # Resolution: 1080p @ 144Hz | Position: To the right of main (2560x0) | Scale: 1
      # 'transform, 1' rotates it 90 degrees (Vertical)
      "DP-2, 1920x1080@144, 2560x0, 1, transform, 1"
      # "DP-2, 1920x1080@144, 1920x0, 1, transform, 1"

    ];

    # Workspace Bindings
    workspace = [
      "1, monitor:DP-1"
      "2, monitor:DP-1"
      "3, monitor:DP-1"
      "4, monitor:DP-1"
      "5, monitor:DP-1"
      "6, monitor:DP-2"
      "7, monitor:DP-2"
      "8, monitor:DP-2"
      "9, monitor:DP-2"
      "10, monitor:DP-2"
    ];

    cursor = {
      no_hardware_cursors = true;
    };
  };
}

{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;

    scripts = [
      # MPRIS so the ags media indicator picks mpv up
      pkgs.mpvScripts.mpris
      # on-the-fly quality switching (Ctrl+f / Alt+f)
      pkgs.mpvScripts.quality-menu
    ];

    bindings = {
      "Ctrl+f" = "script-binding quality_menu/video_formats_toggle";
      "Alt+f" = "script-binding quality_menu/audio_formats_toggle";
    };

    config = {
      # ---- Video renderer ----
      vo = "gpu-next";
      gpu-api = "vulkan";
      hwdec = "auto-safe";

      # ---- Output / dither ----
      dither-depth = "auto";

      # ---- HDR / color management ----
      target-colorspace-hint = true;
      target-peak = 400;
      target-contrast = 1000;

      # ---- Scalers ----
      scale = "ewa_lanczossharp";
      cscale = "ewa_lanczossharp";
      dscale = "mitchell";
      scale-antiring = 0.7;
      cscale-antiring = 0.7;

      # ---- Debanding ----
      deband = false;

      # ---- YouTube ----
      ytdl-format = "bestvideo[height<=?1440]+bestaudio/best";
      script-opts = "ytdl_hook-ytdl_path=yt-dlp";
      ytdl-raw-options = "cookies-from-browser=firefox";

      # ---- Audio / misc ----
      volume = 50;
      audio-display = "no";
      keep-open = true;
      save-position-on-quit = true;
    };
  };
}

{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;

    # Expose mpv on the MPRIS D-Bus interface so the ags media-player indicator
    # (AstalMpris) picks it up like any other player. HM symlinks the script
    # into mpv's scripts dir, so no manual `script=` path is needed.
    scripts = [ pkgs.mpvScripts.mpris ];

    config = {
      # ---- Video renderer ----
      vo = "gpu-next";
      gpu-api = "vulkan";
      hwdec = "auto-safe";

      # ---- Output / dither ----
      # XV272K V5 is 10-bit; let mpv pick the dither depth.
      dither-depth = "auto";

      # ---- HDR / color management ----
      # Hints Hyprland to switch the monitor to HDR for HDR content.
      target-colorspace-hint = true;
      # DisplayHDR 400 panel — real peak brightness, not the spec sheet.
      target-peak = 400;
      # IPS contrast is ~1000:1.
      target-contrast = 1000;

      # ---- Scalers (RX 6800 handles these easily) ----
      scale = "ewa_lanczossharp";
      cscale = "ewa_lanczossharp";
      dscale = "mitchell";
      scale-antiring = 0.7;
      cscale-antiring = 0.7;

      # ---- Debanding ----
      # Off unless banding shows; modern content rarely needs it.
      deband = false;

      # ---- YouTube ----
      ytdl-format = "bestvideo[height<=?1440]+bestaudio/best";
      script-opts = "ytdl_hook-ytdl_path=yt-dlp";
      ytdl-raw-options = "cookies=/home/drishal/Downloads/cookies.txt";

      # ---- Audio / misc ----
      volume = 50;
      audio-display = "no";
      keep-open = true;
      save-position-on-quit = true;
    };
  };
}

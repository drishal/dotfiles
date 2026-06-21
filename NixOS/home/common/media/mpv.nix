{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;

    scripts = [
      # Expose mpv on the MPRIS D-Bus interface so the ags media-player
      # indicator (AstalMpris) picks it up like any other player.
      pkgs.mpvScripts.mpris
      # On-the-fly stream quality switching, bound below (Ctrl+f / Alt+f).
      # Pulls the format list from yt-dlp and reloads at the chosen quality.
      pkgs.mpvScripts.quality-menu
    ];

    # Leave plain `f` as mpv's fullscreen toggle; put quality-menu on Ctrl+f
    # (video formats) and Alt+f (audio formats) — both free by default.
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
      # Pull cookies live from Firefox (unencrypted cookies.sqlite — far more
      # reliable than Chromium keyring decryption, and never goes stale).
      ytdl-raw-options = "cookies-from-browser=firefox";

      # ---- Audio / misc ----
      volume = 50;
      audio-display = "no";
      keep-open = true;
      save-position-on-quit = true;
    };
  };
}

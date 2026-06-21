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
      "Alt+f"  = "script-binding quality_menu/audio_formats_toggle";
    };

    config = {
      # ─────────────────────────────────────────────────────────
      #  GPU: AMD RX 6800 XT (RADV/NAVI21), Hyprland Wayland
      #  Monitors: Acer XV272K V5 (4K@160, 10-bit)
      #            LG UltraGear (1080p@144, 8-bit)
      #  Audio: mpv → EasyEffects (oratory1990) → Spark → Gate
      #
      #  Theming (fonts, OSD colors, sub font, background) is
      #  handled by stylix.targets.mpv — see shared/stylix.nix and
      #  home/common/stylix.nix. Do not duplicate those here.
      # ─────────────────────────────────────────────────────────

      # ---- Video renderer ----
      vo              = "gpu-next";
      gpu-api         = "vulkan";
      # Wayland-native context for zero-copy on Hyprland
      gpu-context     = "waylandvk";
      # Don't try D3D11 on Linux
      gpu-allow-d3d11 = false;

      # ---- Hardware decoding (AMD VCN via VAAPI) ----
      hwdec = "vaapi";

      # ---- Output / dither ----
      # 10-bit Acer benefits from blue-noise dithering; 8-bit LG needs it more
      dither-depth = "auto";
      dither-algo  = "blue-noise";
      dither-size  = 1;

      # ---- HDR / color management ----
      # Both monitors are SDR; settings render SDR correctly and pass HDR through cleanly
      target-colorspace-hint = true;
      target-trc             = "srgb";
      target-prim            = "bt.709";
      # Tone mapping + scene-referred HDR (set even for SDR for future-proofing)
      hdr-compute-peak       = true;
      hdr-peak-percentile    = 99.0;
      hdr-smooth-window      = 10;
      hdr-scene-threshold    = 4.0;
      hdr-display-hlg        = "auto";
      tone-mapping           = "auto";
      tone-mapping-mode      = "auto";
      tone-mapping-lut-size  = 1024;

      # ---- Scalers ----
      # ewa_lanczossharp for upscale (sharpest); ewa_lanczos for chroma (no ring)
      scale           = "ewa_lanczossharp";
      cscale          = "ewa_lanczos";
      dscale          = "mitchell";
      scale-antiring  = 0.7;
      cscale-antiring = 0.7;
      dscale-antiring = 0.7;
      # Dynamic super-resolution ready if explicitly asked
      scale-dsol      = true;
      dscale-factor   = 2.0;

      # ---- Debanding (off by default; tuned for `--deband=yes`) ----
      deband             = false;
      deband-iterations  = 2;
      deband-threshold   = 0.05;
      deband-range       = 16;
      deband-grain       = 8;

      # ---- Interpolation / frame timing ----
      # Display-resample = tear-free on VRR-off Hyprland, no judder
      video-sync         = "display-resample";
      interpolation      = true;
      tscale             = "oversample";
      tscale-radius      = 2.0;
      tscale-clamp       = 0.0;

      # ---- Subtitle sizing (font name and color come from stylix) ----
      osd-bar           = true;
      osd-font-size     = 32;
      sub-font-size     = 44;
      sub-border-size   = 2.5;
      sub-shadow-offset = 1;
      sub-spacing       = 0.4;

      # ---- YouTube / streaming ----
      # Allow up to 4K; prefer AVC1+mp4a for fastest hwdec on VCN
      ytdl-format     = "bestvideo[height<=?2160][vcodec^=avc1]+bestaudio[acodec^=mp4a]/bestvideo[height<=?2160]+bestaudio/best";
      script-opts     = "ytdl_hook-ytdl_path=yt-dlp";
      ytdl-raw-options = "cookies-from-browser=firefox";

      # ---- Audio / misc ----
      # Run at unity; control listening level on the Spark sink (wpctl set-volume).
      # volume-max=150 leaves headroom for recordings that need a bit more.
      volume            = 100;
      volume-max        = 150;
      audio-display     = "no";
      audio-channels    = "stereo";
      audio-spdif       = "no";
      keep-open         = true;
      save-position-on-quit = true;
      cursor-autohide   = "no";

      # ---- Demuxer cache (300 MB enough for 4K@100 Mbps streams) ----
      demuxer-max-bytes      = "300MiB";
      demuxer-max-back-bytes = "150MiB";
    };
  };
}

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
      # i = toggle interpolation, I = cycle tscale kernel, d = toggle deband
      "i" = "cycle-values interpolation yes no";
      "I" = "cycle-values tscale oversample linear catmull_rom mitchell gaussian";
      "d" = "cycle-values deband yes no";
    };

    config = {
      # Tuned for: RX 6800 XT (RADV) on Hyprland, Acer XV272K 4K@160 10-bit +
      # LG UltraGear 1080p@144, audio via EasyEffects → Spark → Gate.
      # Theming is stylix.targets.mpv's job — don't duplicate it here.

      # ---- Video renderer ----
      vo              = "gpu-next";
      gpu-api         = "vulkan";
      # Wayland-native context for zero-copy on Hyprland
      gpu-context     = "waylandvk";

      # ---- Hardware decoding (AMD VCN via Vulkan video — zero-copy) ----
      hwdec = "vulkan";

      # ---- Output / dither ----
      dither-depth = "auto";
      dither        = "ordered";

      # ---- HDR / color management ----
      # Both monitors are SDR; settings render SDR correctly and pass HDR through cleanly
      target-colorspace-hint = true;
      target-trc             = "srgb";
      target-prim            = "bt.709";
      # Tone mapping + scene-referred HDR (set even for SDR for future-proofing)
      hdr-compute-peak         = true;
      hdr-peak-percentile      = 99.0;
      hdr-scene-threshold-low  = 1.0;
      hdr-scene-threshold-high = 4.0;
      tone-mapping             = "auto";

      # ---- Scalers ----
      # ewa_lanczos is much lighter than ewa_lanczossharp; spline36 chroma avoids ringing
      scale           = "ewa_lanczos";
      cscale          = "spline36";
      dscale          = "mitchell";
      scale-antiring  = 0.7;
      cscale-antiring = 0.7;
      dscale-antiring = 0.7;

      # ---- Debanding (off by default; tuned for `--deband=yes`) ----
      deband             = false;
      deband-iterations  = 2;
      deband-threshold   = 0.05;
      deband-range       = 16;
      deband-grain       = 8;

      # ---- Interpolation / frame timing ----
      # Expensive at 24fps→160Hz, so left off; `i` toggles it, Shift+I cycles tscale.
      video-sync         = "audio";
      interpolation      = false;
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
      # Bit-perfect: native PipeWire AO, Spark targeted explicitly so a default-sink
      # change can't divert it. audio-samplerate/audio-format stay UNSET so the file's
      # native rate passes through for WirePlumber to switch on (see hosts/common/audio.nix).
      ao              = "pipewire";
      audio-device    = "pipewire/alsa_output.usb-TTGK_Technology_Co._Ltd_Audiocular_Spark-00.analog-stereo";
      # Start at 40%; fine-tune listening level on the Spark sink (wpctl set-volume).
      # volume-max=150 leaves headroom for recordings that need a bit more.
      volume            = 40;
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

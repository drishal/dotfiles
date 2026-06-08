{
  config,
  inputs,
  pkgs,
  ...
}:
{
  programs = {
    mpv = {
      enable = true;
      config = {
        # --- Renderer: libplacebo-based gpu-next on native Vulkan/RADV ---
        vo = "gpu-next";
        gpu-api = "vulkan";
        gpu-context = "waylandvk";

        # HW decode: vaapi is the reliable native path on RDNA2 (VCN3).
        # (hwdec=vulkan also works but needs RADV_PERFTEST=video_decode set,
        #  since RADV Vulkan-Video is off-by-default until RDNA3.)
        hwdec = "vaapi";

        # High-quality scaling profile (ewa_lanczossharp + HDR tone-mapping).
        # Trivial load for a 6800 XT.
        profile = "high-quality";
        cscale = "ewa_lanczos"; # better chroma upscaling
        dscale = "mitchell"; # clean downscaling for 1440p->display
        dither-depth = "auto";
        deband = true; # kill gradient banding

        # HDR passthrough to display (gpu-next handles tone-mapping otherwise)
        target-colorspace-hint = true;

        # Smooth presentation
        video-sync = "display-resample";
        # interpolation = true;  # enable for motion smoothing (adds slight blur)

        # Generous demuxer cache for network/YouTube playback
        cache = true;
        demuxer-max-bytes = "150MiB";
        demuxer-max-back-bytes = "75MiB";

        # --- Audio ---
        ao = "pipewire";
        volume = 70;
        volume-max = 130;

        # --- Subtitles ---
        sub-auto = "fuzzy";
        slang = "en";

        # --- youtube-dl / yt-dlp ---
        ytdl-format = "bestvideo[height<=?1440]+bestaudio/best";
        #script-opts = ytdl_hook-ytdl_path="yt-dlp";
      };
    };
  };
}

{ ... }:
{
  programs.yt-dlp = {
    enable = true;

    settings = {
      downloader = "aria2c";
      # aria2c can't multiplex a single fragment, so fetch fragments in parallel instead.
      concurrent-fragments = 8;
      retries = 10;
      fragment-retries = 10;
      embed-metadata = true;
      embed-thumbnail = true;
      embed-subs = true;
      sub-langs = "en.*";
    };

    # Must live here, not in settings: the value contains spaces and the module emits
    # it unquoted, which yt-dlp's shlex-based config parser would split into stray args.
    # Fragmented HLS/DASH is many small files, so falloc and the big disk cache from
    # aria2.conf are wasted here — override both.
    extraConfig = ''
      --downloader-args "aria2c:-x8 -s8 -k4M --file-allocation=none --disk-cache=32M --console-log-level=warn --summary-interval=0"
    '';
  };
}

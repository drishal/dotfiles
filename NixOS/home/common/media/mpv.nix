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
        volume = 70;
        sub-auto = "fuzzy";
        slang = "en";
        ao = "pipewire";
        hwdec = "auto";
        gpu-context = "wayland";
        ytdl-format = "bestvideo[height<=?1440]+bestaudio/best";
        #script-opts = ytdl_hook-ytdl_path="yt-dlp";
      };
    };
  };
}

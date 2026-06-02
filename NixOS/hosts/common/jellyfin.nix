{ lib, ... }:

{
  services.jellyfin = {
    enable = true;
    # Jellyfin's default HTTP port is 8096.
    openFirewall = true;

    # Enable AMD VAAPI hardware acceleration and configure the device.
    hardwareAcceleration = {
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
    transcoding.hardwareDecodingCodecs = {
      h264 = true;
      hevc = true;
      vp9 = true;
      av1 = true;
    };

    # Force encoding config so NixOS is the source of truth for playback settings.
    forceEncodingConfig = true;
  };

  # PrivateUsers=true in the default jellyfin service creates a user namespace
  # that breaks FFmpeg subprocess execution (exit code 243 / SIGPIPE).
  # Disable it so FFmpeg can access /dev/dri and media files properly.
  systemd.services.jellyfin.serviceConfig.PrivateUsers = lib.mkForce false;

  # Allow Jellyfin to access ~/Movies without exposing the rest of $HOME.
  # /home/drishal only needs execute permission so Jellyfin can traverse it.
  # ~/Movies gets recursive read/execute ACLs for existing and future files.
  systemd.tmpfiles.rules = [
    "a+ /home/drishal - - - - u:jellyfin:--x,m::--x"
    "A+ /home/drishal/Movies - - - - u:jellyfin:rX,d:u:jellyfin:rX,m::rX,d:m::rX"
  ];

  # Allow Jellyfin to use AMD VAAPI / hardware transcoding devices.
  users.users.jellyfin.extraGroups = [
    "video"
    "render"
  ];
}

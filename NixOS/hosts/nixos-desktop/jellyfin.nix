{ ... }:

{
  services.jellyfin = {
    enable = true;
    # Jellyfin's default HTTP port is 8096.
    openFirewall = false;
  };

  # Allow Jellyfin to access ~/Movies without exposing the rest of $HOME.
  # /home/drishal only needs execute permission so Jellyfin can traverse it.
  # ~/Movies gets recursive read/execute ACLs for existing and future files.
  systemd.tmpfiles.rules = [
    "a+ /home/drishal - - - - u:jellyfin:--x"
    "A+ /home/drishal/Movies - - - - u:jellyfin:rX,d:u:jellyfin:rX"
  ];

  # Allow Jellyfin to use AMD VAAPI / hardware transcoding devices.
  users.users.jellyfin.extraGroups = [
    "video"
    "render"
  ];
}

{
  config,
  lib,
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland.settings = {
    config = {
      cursor = {
        no_hardware_cursors = true;
      };
    };
    monitor = [
      {
        output = "DP-1";
        mode = "1920x1080";
        position = "0x0";
        scale = 1;
      }
      {
        output = "DP-2";
        mode = "1920x1080";
        position = "1920x0";
        scale = 1;
      }
    ];
    workspace_rule =
      map (i: {
        workspace = toString i;
        monitor = "DP-1";
      }) (lib.range 1 5)
      ++ map (i: {
        workspace = toString i;
        monitor = "DP-2";
      }) (lib.range 6 10);
  };
}

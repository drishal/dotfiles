{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Import the new separated configuration
    ./nixvim.nix
  ];

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-1, 1920x1080, 0x0, 1"
      "DP-2, 1920x1080, 1920x0, 1"
    ];
    workspace = [
      "1, monitor:DP-1"
      "2, monitor:DP-1"
      "3, monitor:DP-1"
      "4, monitor:DP-1"
      "5, monitor:DP-1"
      "6, monitor:DP-2"
      "7, monitor:DP-2"
      "8, monitor:DP-2"
      "9, monitor:DP-2"
      "10, monitor:DP-2"
    ];
  };
}

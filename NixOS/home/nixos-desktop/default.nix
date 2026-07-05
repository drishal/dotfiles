{ ... }:
{
  imports = [
    ./hyprland.nix
    ./sway.nix
  ];

  # Active widget stack (bar / notifications / control-center). Switch requires
  # logout; enum + startup/restart maps live in home/common/desktop/hyprland.nix.
  drishal.widgets = "quickshell";
}

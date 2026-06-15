{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Import the new separated configuration
    ./hyprland.nix
    ./sway.nix
  ];

}

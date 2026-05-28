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
    ./hyprland.nix
    ./sway.nix
  ];

}

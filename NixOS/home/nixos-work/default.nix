{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Import the new separated configuration
    ../common/core/agent-web-ui.nix
    ./hyprland.nix
    ./sway.nix
  ];

}

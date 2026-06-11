{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    # ./browsers
    ./editors
    ./terminals
    ./core/git.nix
    ./core/packages.nix
    ./core/tmux.nix
    ./core/fastfetch.nix

    ./desktop/rofi.nix
    ./desktop/file-managers.nix
    ./desktop/waybar.nix
    ./desktop/hyprland.nix
    ./desktop/sway.nix
    ./desktop/dms.nix
    ./desktop/hermes-app.nix

    ./browsers/betterfox.nix

    ../../shared/stylix.nix
    ./stylix.nix
    ./shells/default.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "drishal";
    homeDirectory = "/home/drishal";
  };
  programs.man.generateCaches = true;
  news.display = "silent";
  nixpkgs.config = {
    allowBroken = true;
    allowUnfree = true;
  };

  home.stateVersion = "25.05";
}

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
    ./core/services.nix
    ./core/symlinks.nix
    ./core/shells.nix
    ./core/aliases.nix
    # ./core/tmux.nix

    ./desktop/rofi.nix
    ./desktop/file-managers.nix
    ./desktop/waybar.nix
    ./desktop/hyprland.nix
    ./desktop/sway.nix
    ./desktop/dms.nix

    ./browsers/betterfox.nix

    ../../shared/stylix.nix
    ./stylix.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "drishal";
    homeDirectory = "/home/drishal";
    sessionVariables = {
      EDITOR = "nvim";
      EZA_ICON_SPACING = "2";
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      PLAYWRIGHT_HOST_PLATFORM_OVERRIDE = "ubuntu-24.04";
    };
  };

  programs.man.generateCaches = true;
  news.display = "silent";
  nixpkgs.config = {
    allowBroken = true;
    allowUnfree = true;
  };

  home.stateVersion = "25.05";
}

{
  config,
  inputs,
  pkgs,
  nix-colors,
  ...
}:
{
  imports = [
    # ./browsers.nix
    ./editors.nix
    ./git.nix
    ./packages.nix
    ./rofi.nix
    ./services.nix
    ./symlinks.nix
    ./terminals.nix
    ./rofi.nix
    ./shells.nix
    ./file-managers.nix
    # ./colors/doompalenight.nix
    # ./tmux.nix
    ./waybar.nix
    ../stylix.nix
    ./stylix.nix
    ./hyprland.nix
    # inputs.nix-colors.homeManagerModules.default
  ];
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # nix settings...use only for single user installs
  # nix = {
  #   package = pkgs.nix;
  #   settings = {
  #     experimental-features = [ "nix-command" "flakes" ];
  #   };
  # };

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = "drishal";
    homeDirectory = "/home/drishal";
    sessionVariables = {
      EDITOR = "nvim";
    };
    # language.base = "en_US.UTF-8";
    # sessionVariables.LOCALES_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    # sessionVariables.LOCALES_ARCHIVE = "/usr/lib/locale/locale-archive";
  };
  programs.man.generateCaches = true;
  news.display = "silent";
  # scheme = "${inputs.tt-schemes}/base16/catppuccin-mocha.yaml";
  # scheme = ./colors/doompalenight.yaml;
  home.stateVersion = "25.05";
}

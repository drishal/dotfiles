{
  config,
  inputs,
  pkgs,
  ...
}:

{
  stylix = {
    targets = {
      emacs.enable = false;
      neovim.enable = false;
      nixvim.enable = false;
      helix.enable = false;
      hyprpaper.enable = true;
      tmux.enable = false;
      rofi.enable = true;
    };
    iconTheme = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };
  };
}

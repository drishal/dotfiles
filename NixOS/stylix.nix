{
  config,
  inputs,
  pkgs,
  ...
}:
{
  scheme = "${inputs.tt-schemes}/base16/catppuccin-mocha.yaml";
  stylix = {
    enable = true;
    # base16Scheme = "${inputs.tt-schemes}/base16/catppuccin-mocha.yaml";
    base16Scheme = "${config.scheme}";
    cursor = {
      package = pkgs.libsForQt5.breeze-qt5;
      name = "breeze_cursors";
      size = 24;
    };
    image = ../wallpapers/darkest_hour.jpg;
    fonts = {
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };

      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };

      monospace = {
        # package = pkgs.noto-fonts;
        package = pkgs.nerdfonts.override {
        fonts = [
          "FantasqueSansMono"
        ];
      };
        name = "FantasqueSansM Nerd Font";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        terminal = 14;
        applications = 10;
        desktop = 10;
      };
    };
    targets = {
      gtk.enable = true;
    };
  };
}

{
  config,
  inputs,
  pkgs,
  ...
}:
{
  # scheme = ./home-config/colors/doomvibrant.yaml;
  stylix = {
    enable = true;
    #base16Scheme = "${config.scheme}";
    # base16Scheme = "${inputs.tt-schemes}/base24/catppuccin-mocha.yaml";
    base16Scheme = "${inputs.tt-schemes}/base16/gruvbox-material-dark-hard.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest-dark-hard.yaml";
    # base16Scheme =  ./home-config/colors/doomone.yaml;
    cursor = {
      package = pkgs.kdePackages.breeze;
      name = "breeze_cursors";
      size = 24;
    };
    # image = ../wallpapers/warm/railtrack.jpg;
    image = ../wallpapers/anime/goku.jpg;
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
        package = pkgs.nerd-fonts.fantasque-sans-mono;
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

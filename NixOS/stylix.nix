{
  config,
  inputs,
  pkgs,
  ...
}:
{
  # scheme = ./home-config/colors/doomvibrant.yaml;
  fonts.fontconfig.enable = true;
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
    image = ../wallpapers/gruvbox/image2.jpg;
    # image = ../wallpapers/anime/tanjiro-kamado-gruv.jpg;
    # image = ../wallpapers/anime/goku.jpg;
    # image = ../wallpapers/darkest_hour.jpg;
    fonts = {
      serif = {
        # package = pkgs.noto-fonts;
        name = "NotoSans Nerd Font";
      };

      sansSerif = {
        # package = pkgs.noto-fonts;
        name = "NotoSans Nerd Font";
      };

      monospace = {
        # package = pkgs.noto-fonts;
        package = pkgs.nerd-fonts.fantasque-sans-mono;
        name = "RecMonoCasual Nerd Font";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        terminal = 12;
        applications = 10;
        desktop = 10;
      };
    };
    targets = {
      gtk.enable = true;
      # firefox.enable = false;
      fish.enable = false;
    };
  };
 }

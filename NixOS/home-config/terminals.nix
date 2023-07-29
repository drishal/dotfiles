{ config, inputs, pkgs, ... }:
{
  programs = {
    # foot terminal
    foot = {
      enable = true;
      server.enable = false;
      settings = {
        main = {
          term = "xterm-256color";
          font = "FantasqueSansM Nerd Font:size=12";
          # font = "ComicShannsMono Nerd Font:size=13";
          dpi-aware = "yes";
          pad = "15x10";
        };
        cursor = {
          color = "282c34 51afef";
        };
        colors = {
          # onedark
          foreground = "bbc2cf";
          background = "282c34";
          regular0 = "282c34"; # black
          regular1 = "ff6c6b"; # red
          regular2 = "98be65"; # green
          regular3 = "ecbe7b"; # yellow
          regular4 = "51afef"; # blue
          regular5 = "c678dd"; # magenta
          regular6 = "46d9ff"; # cyan
          regular7 = "bbc2cf"; # white
        };
      };
    };
  };
}

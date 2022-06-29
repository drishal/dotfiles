{ config, inputs, pkgs, ... }:
{
  programs = {
    foot = {
      enable = true;
      server.enable = false;
      settings = {
        main = {
          term = "xterm-256color";
          font = "FantasqueSansMono Nerd Font";
          dpi-aware = "yes";
        };
      };
    };
  };
}

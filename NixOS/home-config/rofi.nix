{ config, inputs, pkgs, ... }:
{
  programs = {
    rofi = {
      enable = false;
      theme = "${pkgs.rofi}/share/rofi/themes/Arc-Dark.rasi";
      # font="FiraCode Nerd Font 14";
      font = "FantasqueSansMono Nerd Font 14";
      plugins = [
        pkgs.rofi-emoji
      ];
    };
  };
}

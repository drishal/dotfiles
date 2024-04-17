{
  config,
  inputs,
  pkgs,
  ...
}:
{
  programs = {
    rofi = {
      enable = true;
      theme = "${pkgs.rofi-wayland}/share/rofi/themes/Arc-Dark.rasi";
      # font="FiraCode Nerd Font 14";
      font = "FantasqueSansMono Nerd Font 14";
      plugins = with pkgs; [
        rofi-emoji
        glibcLocales
      ];
    };
  };
}

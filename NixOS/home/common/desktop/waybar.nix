{
  config,
  inputs,
  pkgs,
  lib,
  pkgs-master,
  ...
}:
{
  programs.waybar = {
    enable = true;
    # package = pkgs-master.waybar;
    #style = with config.scheme; ''
    style = with config.lib.stylix.colors; ''
      @define-color colbg        #${base00}; 
      @define-color colbg2       #${base02};
      @define-color colfg        #${base05};
      @define-color colgrey      #${base03};
      @define-color colcyan      #${base0C};
      @define-color colgreen     #${base0B};
      @define-color colorange    #${base09};
      @define-color colmagenta   #${base0E};
      @define-color colviolet    #${base0F};
      @define-color colred       #${base08};
      @define-color colyellow    #${base0A};
      ${builtins.readFile ../../../../config/waybar/style.css}
    '';
    settings = {
      mainBar = {
        # layer = "top";
        margin-top = 5;
        margin-left = 5;
        margin-right = 5;
        height = 10;
        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "battery"
          "network"
          "memory"
          "cpu"
          "tray"
        ];
        battery = {
          format = "{icon} {capacity}% ";
          format-icons = [
            "󰁻"
            "󰁽"
            "󰁿"
            "󰂁"
            "󰁹"
          ];
          interval = 10;
        };

        clock = {
          format = "  {:%F (%a) %H:%M:%S}";
          interval = 1;
        };

        cpu = {
          format = "   {}% ";
          max-length = 10;
          interval = 10;
        };

        memory = {
          interval = 30;
          format = "  {used:0.1f}G/{total:0.1f}G ";
        };
        network = {
          format = "{ifname}";
          format-wifi = "   {essid} ({signalStrength}%) ";
          format-ethernet = " 󰈁 {ifname} ";
          format-disconnected = ""; # An empty format will hide the module.
          # format-disconnected = "";
          tooltip-format = "{ifname}";
          tooltip-format-wifi = "  {essid} ({signalStrength}%)  ";
          tooltip-format-ethernet = " 󰈁 {ifname} ";
          tooltip-format-disconnected = "Disconnected";
          max-length = 50;
          interval = 10;
        };

        "hyprland/taskbar" = {
          all-outputs = false;
          current-only = true;
          format = "{icon}";
          icon-size = 9;
          icon-theme = "Papirus";
          tooltip-format = "{title}";
          on-click = "activate";
          on-click-middle = "close";
        };

        "hyprland/workspaces" = {
          all-outputs = false;
          active-only = false;
          sort-by-number = true;
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "0" = "10";
          };

          format = "{name}";
        };

        "hyprland/window" = {
          format = "{}";
          separate-outputs = true;
        };

        tray = {
          icon-size = 19;
          spacing = 10;
        };
      };
    };
  };
}

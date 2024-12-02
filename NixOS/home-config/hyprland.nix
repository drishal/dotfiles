{
  config,
  inputs,
  pkgs,
  ...
}:

{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        col.active_border = "rgba(bd93f9ff)";
        col.inactive_border = "rgba(3f444aff)";
        layout = "master";
        # cursor_inactive_timeout = 3
      };
      input = {
        kb_layout = "us";
        repeat_rate = 50;
        repeat_delay = 300;
        follow_mouse = 1;
        touchpad = {
          natural_scroll = "no";
        };
        sensitivity = 0.5;
      };

      decoration = {
        rounding = 7;
        # blur = yes;
        # blur_size = 5;
        # blur_passes = 1;
        blurls = "waybar";
        # drop_shadow = yes;
        # shadow_range = 4;
        # shadow_render_power = 3;
        # col.shadow = rgba(1a1a1aee);
        blur = {
          enabled = false;
          new_optimizations = true;
          size = 8;
          passes = 3;
          noise = 0.04;
          brightness = 0.9;
          contrast = 0.9;
          popups = true;
        };
      };
    };
  };
}

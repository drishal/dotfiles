{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [ inputs.hyprpanel.homeManagerModules.hyprpanel ];
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    settings = {
      exec-once = [
        "lxpolkit & waybar & swaync & nm-applet --indicator &  blueman-applet & emacs --daemon & foot --server"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      ];
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        #"col.active_border" = "rgba(bd93f9ff)";
        #"col.inactive_border" = "rgba(3f444aff)";
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
        # sensitivity = 0.5;
        accel_profile = "flat";

      };

      decoration = {
        rounding = 7;
        # blur = yes;
        # blur_size = 5;
        # blur_passes = 1;
        # blurls = "waybar";
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

      xwayland = {
        force_zero_scaling = true;
      };

      render = {
        explicit_sync = 1;
      };
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 5, myBezier"
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 8, default"
          "borderangle, 1, 6, default"
          "fade, 1, 5, default"
          "workspaces, 1, 4, default"
        ];
      };
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      master = {
        mfact = 0.5;
        new_status = "master";
      };
      gestures = {
        workspace_swipe = true;
      };
      windowrulev2 = [
        "rounding 0, class:^[fF]irefox"
        "float, class:Waydroid"
        "float, class:^(Anydesk)$,title:^(anydesk)$"
      ];
      windowrule = [
        "opacity 0.0 override, class:^(xwaylandvideobridge)$"
        "noanim, class:^(xwaylandvideobridge)$"
        "noinitialfocus, class:^(xwaylandvideobridge)$"
        "maxsize 1 1, class:^(xwaylandvideobridge)$"
        "noblur, class:^(xwaylandvideobridge)$"
        "nofocus, class:^(xwaylandvideobridge)$"
      ];
      # experimental = {
      #   hdr = true;
      #   wide_color_gamut = true;
      #   xx_color_management_v4 = true;
      # };
      # layerrule = [
      #   "ignorealpha 0.1, waybar"
      #   "blur, waybar"
      # ];
      "$mainMod" = "SUPER";
      bind = [
        "$mainMod, RETURN, exec, footclient"
        # "$mainMod, RETURN, exec, kitty --single-instance"
        "$mainMod, D, exec, rofi -show drun -icon-theme Papirus -show-icons"
        "$mainMod, V, exec, pavucontrol"
        "$mainMod, T, exec, GDK_BACKEND=x11 xfce4-taskmanager"
        "$mainMod, Q, killactive, "
        "$mainMod SHIFT, Q, exec, kill -9 $(pidof Hyprland)"
        # "$mainMod SHIFT, F, exec, firefox"
        "$mainMod SHIFT, F, exec, zen"
        "$mainMod SHIFT, L, exec, swaylock --screenshots --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5 --ring-color bb00cc --key-hl-color 880033 --line-color 00000000 --inside-color 00000088 --separator-color 00000000  --fade-in 0.2"
        "$mainMod, E, exec, nemo"
        # "$mainMod, x, exec, pkill waybar; waybar"
        "$mainMod, x, exec, pkill waybar; waybar"
        "$mainMod SHIFT, X, exec, loginctl terminate-user $USER"
        "$mainMod, A, exec, emacsclient -c"
        "$mainMod, SPACE, togglefloating, "
        "$mainMod, F,fullscreen,"
        "$mainMod SHIFT, s, exec, grimshot copy area"
        "$mainMod, s, exec, grimshot copy output"
        # "$mainMod, K, movefocus, u"
        # "$mainMod, J, movefocus, d"
        "$mainMod, K, cyclenext"
        "$mainMod, J, cyclenext, prev"
        "$mainMod SHIFT, M, exec, hyprctl keyword general:layout master"
        "$mainMod ,H,resizeactive,-20 0"
        "$mainMod ,L,resizeactive, 20 0"
        "$mainMod CTRL ,J, resizeactive, 0 20"
        "$mainMod SHIFT ,J,layoutmsg, swapprev"
        "$mainMod SHIFT ,K,layoutmsg,swapnext"
        "$mainMod ,M,layoutmsg,swapwithmaster"
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };

  #hyprpanel
  # programs.hyprpanel = {
  #   enable = false;
  #   overlay.enable = true;
  #   systemd.enable = false;
  #   hyprland.enable = true;
  #   theme = "catppuccin_mocha";
  #   layout = {
  #     "bar.layouts" = {
  #       "*" = {
  #         left = [
  #           "dashboard"
  #           "workspaces"
  #           "windowtitle"
  #         ];
  #         middle = [
  #           "clock"
  #           "notifications"
  #         ];
  #         right = [
  #           "volume"
  #           "network"
  #           "ram"
  #           "cpu"
  #           "power"
  #           "systray"
  #         ];
  #       };
  #     };
  #   };

  #   settings = {
  #     bar.launcher.icon = "";
  #     bar.workspaces.show_numbered = true;
  #     theme.bar.border_radius = "1.0em";
  #     theme.font = {
  #       name = "${config.stylix.fonts.monospace.name}";
  #       size = "${builtins.toString config.stylix.fonts.sizes.terminal}px";
  #     };
  #   };
  # };
  # programs.hyprlock.enable = true;
}

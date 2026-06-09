{
  config,
  lib,
  pkgs,
  ...
}:

let
  swaylockCmd =
    "swaylock --screenshots --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5 --ring-color bb00cc --key-hl-color 880033 --line-color 00000000 --inside-color 00000088 --separator-color 00000000 --fade-in 0.2";
in
{
  wayland.windowManager.sway = {
    enable = true;
    package = null; # Use the NixOS sway module package (has proper wrappers for NVIDIA etc.)
    xwayland = true;
    systemd.enable = true;

    config = {
      # --- Core ---
      modifier = "Mod4"; # SUPER key
      terminal = "kitty";
      menu = "rofi -show drun -icon-theme Papirus -show-icons";

      # --- Gaps (from hyprland general) ---
      gaps = {
        inner = 5;
        outer = 20;
      };

      # --- Window appearance ---
      window = {
        border = 2;
        titlebar = false;
      };

      # --- Floating modifier (from hyprland bindm) ---
      floating.modifier = "Mod4";

      # --- Focus ---
      focus = {
        followMouse = true;
        mouseWarping = true;
        newWindow = "smart";
      };

      # --- Input (from hyprland input section) ---
      input = {
        "*" = {
          xkb_layout = "us";
          repeat_rate = "50";
          repeat_delay = "300";
          accel_profile = "flat";
        };
        "type:touchpad" = {
          natural_scroll = "disabled";
        };
      };

      # --- Seat / cursor ---
      seat = {
        "*" = {
          hide_cursor = "when-typing enable";
        };
      };

      # --- Disable default bar (using DMS instead) ---
      bars = [ ];

      # --- Startup (from hyprland exec-once) ---
      startup = [
        { command = "lxpolkit & dms run & nm-applet --indicator & blueman-applet"; }
        { command = "swaybg -i ${config.stylix.image} -m fill"; }
        { command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"; }
      ];

      # --- Keybindings (ported from hyprland bind) ---
      keybindings =
        let
          mod = config.wayland.windowManager.sway.config.modifier;
        in
        lib.mkOptionDefault {
          # Launchers
          "${mod}+Return" = "exec kitty";
          "${mod}+d" = "exec rofi -show drun -icon-theme Papirus -show-icons";
          "${mod}+v" = "exec pavucontrol";
          "${mod}+t" = "exec GDK_BACKEND=x11 xfce4-taskmanager";
          "${mod}+e" = "exec nemo";
          "${mod}+a" = "exec emacsclient -c";

          # Window management
          "${mod}+q" = "kill";
          "${mod}+Shift+q" = "exec swaymsg exit";
          "${mod}+space" = "floating toggle";
          "${mod}+f" = "fullscreen toggle";

          # Apps
          "${mod}+Shift+f" = "exec firefox";
          "${mod}+Shift+l" = "exec ${swaylockCmd}";

          # DMS restart (port of "pkill dms; dms run")
          "${mod}+x" = "exec pkill dms; dms run";

          # Session
          "${mod}+Shift+x" = "exec loginctl terminate-user $USER";

          # Screenshots (same grimshot as hyprland)
          "${mod}+Shift+s" = "exec grimshot copy area";
          "${mod}+s" = "exec grimshot copy output";

          # Focus (hyprland cyclenext → sway focus)
          "${mod}+k" = "focus up";
          "${mod}+j" = "focus down";

          # Resize (hyprland resizeactive → sway resize)
          "${mod}+h" = "resize shrink width 20px";
          "${mod}+l" = "resize grow width 20px";
          "${mod}+Ctrl+j" = "resize grow height 20px";

          # Layout
          "${mod}+Shift+m" = "layout default";
          "${mod}+Shift+j" = "move up";
          "${mod}+Shift+k" = "move down";
          "${mod}+m" = "move scratchpad";

          # Workspace switching
          "${mod}+1" = "workspace 1";
          "${mod}+2" = "workspace 2";
          "${mod}+3" = "workspace 3";
          "${mod}+4" = "workspace 4";
          "${mod}+5" = "workspace 5";
          "${mod}+6" = "workspace 6";
          "${mod}+7" = "workspace 7";
          "${mod}+8" = "workspace 8";
          "${mod}+9" = "workspace 9";
          "${mod}+0" = "workspace 10";

          # Move window to workspace
          "${mod}+Shift+1" = "move container to workspace 1";
          "${mod}+Shift+2" = "move container to workspace 2";
          "${mod}+Shift+3" = "move container to workspace 3";
          "${mod}+Shift+4" = "move container to workspace 4";
          "${mod}+Shift+5" = "move container to workspace 5";
          "${mod}+Shift+6" = "move container to workspace 6";
          "${mod}+Shift+7" = "move container to workspace 7";
          "${mod}+Shift+8" = "move container to workspace 8";
          "${mod}+Shift+9" = "move container to workspace 9";
          "${mod}+Shift+0" = "move container to workspace 10";

          # Layout toggles
          "${mod}+b" = "splith";
          "${mod}+Shift+b" = "splitv";
          "${mod}+Shift+space" = "floating toggle";
        };

      # --- Modes ---
      modes = {
        resize = {
          "h" = "resize shrink width 20px";
          "l" = "resize grow width 20px";
          "j" = "resize grow height 20px";
          "k" = "resize shrink height 20px";
          "Escape" = "mode default";
          "Return" = "mode default";
        };
      };
    };

    # Extra config for things not covered by the HM module
    extraConfig = ''
      # Default layout for new workspaces (closest to hyprland's master layout)
      workspace_layout default

      # Title bar font
      title_align center

      # Scroll through workspaces with mod + scroll (needs --whole-window)
      bindsym --whole-window Mod4+button5 workspace next
      bindsym --whole-window Mod4+button4 workspace prev

      # Mouse bindings (from hyprland bindm)
      bindgesture swipe:3:left workspace next
      bindgesture swipe:3:right workspace prev

      # Drag floating windows with $mod + left click, resize with right click
      # (handled by floating.modifier above)
    '';
  };
}

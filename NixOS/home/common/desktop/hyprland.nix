{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.generators) mkLuaInline;

  # `combo`/`comboWith` build the key-combo string referencing the `mainMod`
  # Lua local (rendered from the `_var` entry below).
  combo = key: mkLuaInline ''mainMod .. " + ${key}"'';
  # A bind entry: combo + dispatcher (both raw Lua expressions).
  bind = c: disp: { _args = [ c disp ]; };
  # Convenience for exec_cmd binds.
  exec = cmd: mkLuaInline ''hl.dsp.exec_cmd("${cmd}")'';

  # Switch (SUPER+N) and move-to (SUPER+SHIFT+N) workspace binds for 1..10.
  # Key 10 is bound to the "0" key, matching the old hyprlang config.
  wsKey = i: if i == 10 then "0" else toString i;
  workspaceBinds =
    map (i: bind (combo (wsKey i)) (mkLuaInline "hl.dsp.focus({ workspace = ${toString i} })")) (
      lib.range 1 10
    )
    ++ map (
      i: bind (combo "SHIFT + ${wsKey i}") (mkLuaInline "hl.dsp.window.move({ workspace = ${toString i} })")
    ) (lib.range 1 10);
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    settings = {
      # Variables → Lua locals (local mainMod = "SUPER", local terminal = "kitty")
      mainMod = {
        _var = "SUPER";
      };
      terminal = {
        _var = "kitty";
      };

      # Autostart → hl.on("hyprland.start", ...). Rendered as a list so per-host
      # modules can append their own start hooks.
      on = [
        {
          _args = [
            "hyprland.start"
            (mkLuaInline ''
              function()
                hl.exec_cmd("lxpolkit & dms run &  nm-applet --indicator &  blueman-applet")
                hl.exec_cmd("hyprpaper")
                hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
                -- cliphist storer daemons: capture both text and image copies so
                -- the rofi (ags) and wofi clipboard menus have history to show.
                hl.exec_cmd("wl-paste --type text --watch cliphist store")
                hl.exec_cmd("wl-paste --type image --watch cliphist store")
              end'')
          ];
        }
      ];

      # Keyword sections → a single hl.config({ ... }) call.
      config = {
        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          #"col.active_border" = "rgba(bd93f9ff)";
          #"col.inactive_border" = "rgba(3f444aff)";
          layout = "master";
        };
        input = {
          kb_layout = "us";
          repeat_rate = 50;
          repeat_delay = 300;
          follow_mouse = 1;
          touchpad = {
            natural_scroll = false;
          };
          # sensitivity = 0.5;
          accel_profile = "flat";
        };
        decoration = {
          rounding = 7;
          blur = {
            enabled = true;
            size = 8;
            passes = 3;
            noise = 0.04;
            brightness = 0.9;
            contrast = 0.9;
            popups = true;
          };
        };
        master = {
          mfact = 0.5;
          new_status = "master";
        };
        xwayland = {
          force_zero_scaling = true;
        };
        animations = {
          enabled = true;
        };
      };

      # Beziers → hl.curve(name, { type = "bezier", points = {...} })
      curve = {
        _args = [
          "myBezier"
          {
            type = "bezier";
            points = [
              [
                0.05
                0.9
              ]
              [
                0.1
                1.05
              ]
            ];
          }
        ];
      };

      # Animations → one hl.animation({ ... }) call per rule.
      animation = [
        {
          leaf = "windows";
          enabled = true;
          speed = 5;
          bezier = "myBezier";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 5;
          bezier = "default";
          style = "popin 80%";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 8;
          bezier = "default";
        }
        {
          leaf = "borderangle";
          enabled = true;
          speed = 6;
          bezier = "default";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 5;
          bezier = "default";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 4;
          bezier = "default";
        }
      ];

      # Float, size and center the yazi watch-sync popup (toggled with W in yazi).
      window_rule = [
        {
          name = "watch-sync-float";
          match = {
            class = "watch-sync-float";
          };
          float = true;
          size = "900 460";
          center = true;
        }
      ];

      bind =
        [
          (bind (combo "RETURN") (mkLuaInline "hl.dsp.exec_cmd(terminal)"))
          # (bind (combo "RETURN") (exec "kitty --single-instance"))
          (bind (combo "D") (exec "rofi -show drun -icon-theme Papirus -show-icons"))
          (bind (combo "V") (exec "pavucontrol"))
          # wofi clipboard history with image thumbnails (rofi stays the default
          # launcher; this is a dedicated image-aware clipboard picker).
          (bind (combo "SHIFT + V") (exec "${config.home.homeDirectory}/dotfiles/scripts/clipboard-wofi.sh"))
          (bind (combo "T") (exec "GDK_BACKEND=x11 xfce4-taskmanager"))
          (bind (combo "Q") (mkLuaInline "hl.dsp.window.close()"))
          (bind (combo "SHIFT + Q") (exec "kill -9 $(pidof Hyprland)"))
          (bind (combo "SHIFT + F") (exec "firefox"))
          (bind (combo "SHIFT + L") (
            exec "swaylock --screenshots --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5 --ring-color bb00cc --key-hl-color 880033 --line-color 00000000 --inside-color 00000088 --separator-color 00000000  --fade-in 0.2"
          ))
          (bind (combo "E") (exec "nemo"))
          (bind (combo "x") (exec "pkill dms; dms run"))
          (bind (combo "SHIFT + X") (mkLuaInline "hl.dsp.exit()"))
          (bind (combo "A") (exec "emacsclient -c"))
          (bind (combo "SPACE") (mkLuaInline ''hl.dsp.window.float({ action = "toggle" })''))
          (bind (combo "F") (mkLuaInline "hl.dsp.window.fullscreen()"))
          (bind (combo "SHIFT + s") (exec "grimshot copy area"))
          (bind (combo "s") (exec "grimshot copy output"))
          (bind (combo "K") (mkLuaInline "hl.dsp.window.cycle_next()"))
          (bind (combo "J") (mkLuaInline "hl.dsp.window.cycle_next({ next = false })"))
          (bind (combo "SHIFT + M") (exec "hyprctl keyword general:layout master"))
          (bind (combo "H") (mkLuaInline "hl.dsp.window.resize({ x = -20, y = 0, relative = true })"))
          (bind (combo "L") (mkLuaInline "hl.dsp.window.resize({ x = 20, y = 0, relative = true })"))
          (bind (combo "CTRL + J") (mkLuaInline "hl.dsp.window.resize({ x = 0, y = 20, relative = true })"))
          (bind (combo "SHIFT + J") (mkLuaInline ''hl.dsp.layout("swapprev")''))
          (bind (combo "SHIFT + K") (mkLuaInline ''hl.dsp.layout("swapnext")''))
          (bind (combo "M") (mkLuaInline ''hl.dsp.layout("swapwithmaster")''))
        ]
        ++ workspaceBinds
        ++ [
          # Scroll through workspaces with mainMod + scroll
          (bind (combo "mouse_down") (mkLuaInline ''hl.dsp.focus({ workspace = "e+1" })''))
          (bind (combo "mouse_up") (mkLuaInline ''hl.dsp.focus({ workspace = "e-1" })''))

          # Move/resize windows with mainMod + LMB/RMB (was bindm in hyprlang)
          {
            _args = [
              (combo "mouse:272")
              (mkLuaInline "hl.dsp.window.drag()")
              { mouse = true; }
            ];
          }
          {
            _args = [
              (combo "mouse:273")
              (mkLuaInline "hl.dsp.window.resize()")
              { mouse = true; }
            ];
          }

          # Media keys (no modifier)
          (bind "XF86AudioRaiseVolume" (exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
          (bind "XF86AudioLowerVolume" (exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-"))
          (bind "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
        ];
    };
  };

  services.hyprpaper.package = null;
}

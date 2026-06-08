{
  config,
  inputs,
  pkgs,
  ...
}:
{
  programs = {
    foot = {
      enable = true;
      server.enable = true;
      settings = {
        tweak = {
          delayed-render-lower = 0;
          delayed-render-upper=0;
        };
        main = {
          dpi-aware = "no";
          pad = "15x10";
          gamma-correct-blending = false;

        };
        colors = with config.lib.stylix.colors; {
          cursor = "${base00} ${base06}";
        };
        scrollback = {
          indicator-position = "none";
        };
      };
    };

    rio = {
      enable = true;
      settings = {
        blinking-cursor = false;
      };
    };

    alacritty = {
      enable = true;
      settings = {
        window = {
          dynamic_title = true;
          dynamic_padding = true;
          padding = {
            x = 5;
            y = 5;
          };
        };
      };
    };
    kitty = {
      shellIntegration.mode = "no-cursor no-cwd no-prompt-mark";
      enable = true;
      settings = {
        confirm_os_window_close = 0;
        cursor_blink_interval = 0;
        cursor_shape = "block";
        enable_audio_bell = false;
        input_delay = 0;
        repaint_delay = 2;
        sync_to_monitor = true;
        update_check_interval = 0;
        wayland_enable_ime  = false;
        window_padding_width = 5;
        clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
      };
    };
    zellij = {
      enable = true;
    };
    ghostty = {
      enable = true;
      settings = {
        # theme = "Gruvbox Material Dark";
        # font-family = "${config.stylix.fonts.monospace.name}";
        # font-size = config.stylix.fonts.sizes.terminal;
        window-padding-x = 5;
        window-padding-y = 5;
        cursor-style = "block";
        cursor-style-blink = false;
        shell-integration-features = "no-cursor";
      };
    };
    wezterm = {
      enable = true;
      extraConfig =
        ''
        config.enable_wayland = true;
        config.ssh_backend = "Ssh2"
        config.front_end = "WebGpu";
        config.enable_scroll_bar = true;
        config.enable_tab_bar = false;
        '';
      
    };
  };
}

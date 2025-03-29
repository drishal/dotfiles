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
      server.enable = false;
      settings = {
        main = {
          # term = "xterm-256color";
          # font = "FantasqueSansM Nerd Font:size=14";
          dpi-aware = "no";
          pad = "15x10";
        };
        # cursor = with config.scheme; {
        cursor = with config.lib.stylix.colors; {
          color = "${base00} ${base06}";
        };
        scrollback = {
          indicator-position = "none";
        };
        # colors = with config.scheme; {
        #   foreground = "${base05}"; # Text
        #   background = "${base00}"; # Base
        #   regular0 = "${base03}"; # Surface 1
        #   regular1 = "${base08}"; # red
        #   regular2 = "${base0B}"; # green
        #   regular3 = "${base0A}"; # yellow
        #   regular4 = "${base0D}"; # blue
        #   regular5 = "${base0E}"; # magenta
        #   regular6 = "${base0C}"; # cyan
        #   regular7 = "${base07}"; # white
        #   bright0 = "${base04}";
        #   bright1 = "${base08}";
        #   bright2 = "${base0B}";
        #   bright3 = "${base0A}";
        #   bright4 = "${base0D}";
        #   bright5 = "${base0E}";
        #   bright6 = "${base0C}";
        #   bright7 = "${base07}";
        # };
      };
    };

    rio = {
      enable = true;
      settings = {
        # cursor = '▇';
        blinking-cursor = false;
        # theme="dracula";
        # fonts = {
        #   size = 18;
        #   family = "FantasqueSansM Nerd Font";
        # };
        # colors = with config.lib.stylix.colors; {
        #   background = "#${base00}";
        #   foreground = "#${base05}";
        #   cursor = "#${base0D}";
        #   bright-cursor = "#${base0C}";
        #   bright-black = "#${base00}";
        #   bright-blue = "#${base0D}";
        #   bright-cyan = "#${base0C}";
        #   bright-green = "#${base0B}";
        #   bright-magenta = "#${base0E}";
        #   bright-red = "#${base08}";
        #   bright-white = "#${base06}";
        #   bright-yellow = "#${base09}";
        #   black = "#${base00}";
        #   blue = "#${base0D}";
        #   cyan = "#${base0C}";
        #   green = "#${base0B}";
        #   magenta = "#${base0E}";
        #   red = "#${base08}";
        #   white = "#${base05}";
        #   yellow = "#${base0A}";
        # };
      };
    };

    alacritty = {
      enable = true;
      settings = {
        # colors = with config.scheme; {
        #   bright = {
        #     black = "0x${base00}";
        #     blue = "0x${base0D}";
        #     cyan = "0x${base0C}";
        #     green = "0x${base0B}";
        #     magenta = "0x${base0E}";
        #     red = "0x${base08}";
        #     white = "0x${base06}";
        #     yellow = "0x${base09}";
        #   };
        #   cursor = {
        #     cursor = "0x${base0D}";
        #     text = "0x${base07}";
        #   };
        #   normal = {
        #     black = "0x${base00}";
        #     blue = "0x${base0D}";
        #     cyan = "0x${base0C}";
        #     green = "0x${base0B}";
        #     magenta = "0x${base0E}";
        #     red = "0x${base08}";
        #     white = "0x${base05}";
        #     yellow = "0x${base0A}";
        #   };
        #   primary = {
        #     background = "0x${base00}";
        #     foreground = "0x${base05}";
        #   };
        # };
        window = {
          dynamic_title = true;
          dynamic_padding = true;
          padding = {
            x = 5;
            y = 5;
          };
        };
        # font = {
        #   normal = {
        #     family = "FantasqueSansM Nerd Font";
        #     # family="monospace";
        #   };
        #   size = 13;
        # };
      };
    };
    kitty = {
      enable = true;
      settings = {
        enable_audio_bell = false;
        update_check_interval = 0;
        window_padding_width = 5;
        confirm_os_window_close = 0;
      };
    };
    zellij = {
      enable = true;
    };
    ghostty = {
      enable = true;
      settings = {
        theme = "gruvbox-material";
        font-family = "${config.stylix.fonts.monospace.name}";
        font-size = config.stylix.fonts.sizes.terminal;
        window-padding-x = 5;
        window-padding-y = 5;
        cursor-style = "block";
        cursor-style-blink = false;
        shell-integration-features = "no-cursor";
      };
    };
  };
}

{
  config,
  pkgs,
  ...
}:
let
  c = config.lib.stylix.colors.withHashtag;
  sans = config.stylix.fonts.sansSerif.name;

  # Grid launcher in the quickshell tokens (card/ink/accent, 22/16px radii).
  # flow: horizontal + scroll-method 1 make the wheel move one row at a time.
  theme = ''
    * {
      bg: ${c.base00};
      card: ${c.base01};
      hi: ${c.base02};
      ink: ${c.base05};
      dim: ${c.base04};
      accent: ${c.base0D};
      accent-soft: ${c.base0D}2e;

      font: "${sans} Medium 11";
      background-color: transparent;
      text-color: @ink;
      margin: 0;
      padding: 0;
      spacing: 0;
    }

    window {
      location: center;
      anchor: center;
      width: 760px;
      border: 1px;
      border-color: @hi;
      border-radius: 22px;
      background-color: @bg;
    }

    mainbox {
      padding: 14px;
      spacing: 6px;
      children: [ "inputbar", "message", "listview" ];
    }

    inputbar {
      spacing: 10px;
      padding: 8px 12px 12px 12px;
      children: [ "textbox-search", "entry", "num-filtered-rows", "textbox-num-sep", "num-rows" ];
    }

    textbox-search {
      expand: false;
      str: "󰍉";
      font: "Symbols Nerd Font Mono 17";
      text-color: @accent;
      vertical-align: 0.5;
    }

    entry {
      vertical-align: 0.5;
      placeholder: "Search apps";
      font: "${sans} 13";
      placeholder-color: @dim;
      cursor: text;
    }

    num-filtered-rows, num-rows, textbox-num-sep {
      expand: false;
      vertical-align: 0.5;
      text-color: @dim;
      font: "${sans} 10";
    }
    textbox-num-sep { str: "/"; }

    message {
      padding: 10px 14px;
      border-radius: 14px;
      background-color: @card;
    }
    textbox { text-color: @ink; }

    listview {
      columns: 6;
      lines: 3;
      flow: horizontal;
      fixed-height: true;
      fixed-columns: true;
      cycle: false;
      scrollbar: true;
      spacing: 4px;
      padding: 4px 0 0 0;
    }

    scrollbar {
      handle-width: 6px;
      handle-rounded-corners: true;
      handle-color: @dim;
      border-radius: 3px;
      background-color: @card;
    }

    element {
      orientation: vertical;
      spacing: 8px;
      padding: 16px 6px 12px 6px;
      border-radius: 16px;
      cursor: pointer;
    }
    element normal.normal, element alternate.normal,
    element normal.active, element alternate.active,
    element normal.urgent, element alternate.urgent {
      background-color: transparent;
      text-color: @ink;
    }
    element selected.normal, element selected.active, element selected.urgent {
      background-color: @accent-soft;
      text-color: @ink;
    }

    element-icon {
      size: 52px;
      horizontal-align: 0.5;
      cursor: inherit;
    }

    element-text {
      horizontal-align: 0.5;
      font: "${sans} 10";
      text-color: inherit;
      cursor: inherit;
    }
  '';
in
{
  programs = {
    rofi = {
      enable = true;
      theme = "launcher";
      settings = {
        show-icons = true;
        icon-theme = config.stylix.icons.dark;
        drun-display-format = "{name}";
        display-drun = "";
        # Single click launches; wheel and keys still move the selection.
        me-select-entry = "";
        me-accept-entry = "MousePrimary";
        scroll-method = 1;
      };
      plugins = with pkgs; [
        rofi-emoji
        glibcLocales
      ];
    };
  };

  xdg.dataFile."rofi/themes/launcher.rasi".text = theme;
}

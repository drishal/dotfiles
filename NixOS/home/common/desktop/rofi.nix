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

  # Raycast-style palette: the grid's tokens as a single-column list, with the
  # mode tabs as a bottom bar. Follow-up dmenus (confirm, audio output) get a prompt instead.
  paletteTheme = ''
    @import "launcher"

    window { width: 720px; }

    mainbox {
      padding: 12px;
      spacing: 8px;
      children: [ "inputbar", "message", "listview", "mode-switcher" ];
    }

    inputbar {
      padding: 6px 10px 14px 10px;
      border: 0 0 1px 0;
      border-color: @hi;
    }
    entry { placeholder: "Search"; }

    listview {
      columns: 1;
      lines: 8;
      flow: vertical;
      scrollbar: false;
      spacing: 2px;
      padding: 0;
    }

    element {
      orientation: horizontal;
      spacing: 12px;
      padding: 8px 12px;
      border-radius: 12px;
    }
    element-icon { size: 30px; }
    element-text {
      horizontal-align: 0;
      vertical-align: 0.5;
      font: "${sans} 11";
    }

    mode-switcher {
      spacing: 4px;
      padding: 10px 0 0 0;
      border: 1px 0 0 0;
      border-color: @hi;
    }
    button {
      padding: 6px 10px;
      border-radius: 10px;
      font: "${sans} 10";
      text-color: @dim;
      horizontal-align: 0.5;
      cursor: pointer;
    }
    button selected {
      background-color: @accent-soft;
      text-color: @ink;
    }

    prompt {
      padding: 4px 10px;
      border-radius: 10px;
      background-color: @accent-soft;
      vertical-align: 0.5;
      font: "${sans} 10";
    }

    @media (enabled: DMENU) {
      mainbox { children: [ "inputbar", "message", "listview" ]; }
      inputbar { children: [ "prompt", "entry" ]; }
      entry { placeholder: "Filter"; }
      listview { lines: 6; }
    }
  '';

  mkMode =
    name: runtimeInputs:
    pkgs.writeShellApplication {
      name = "rofi-${name}";
      inherit runtimeInputs;
      text = builtins.readFile ../../../../scripts/rofi/${name}.sh;
    };

  clipMode = mkMode "clip" (with pkgs; [ cliphist wl-clipboard ]);
  webMode = mkMode "web" (with pkgs; [ jq xdg-utils ]);
  # capture, hyprctl and swaymsg come from the session (capture is installed by hyprland.nix).
  commandsMode = mkMode "commands" (
    with pkgs;
    [
      cliphist
      glib # gio
      hyprpicker
      jq
      libnotify
      networkmanager
      bluez
      pipewire
      playerctl
      wireplumber
    ]
  );

  # One rofi, one tab per mode: Ctrl+Tab / Shift+Arrow or a click switches tabs.
  palette = pkgs.writeShellApplication {
    name = "rofi-palette";
    text = ''
      mode=''${1:-combi}
      shift || true
      exec ${config.programs.rofi.finalPackage}/bin/rofi -show "$mode" -theme palette \
        -modes "combi,window,clipboard:${clipMode}/bin/rofi-clip,calc,emoji,web:${webMode}/bin/rofi-web,filebrowser" \
        -combi-modes "drun,commands:${commandsMode}/bin/rofi-commands" \
        -combi-display-format "{text}" \
        -drun-display-format "{name}[<span alpha='55%' size='small'>   {generic}</span>]" \
        -window-format "{t}<span alpha='55%' size='small'>   {c}</span>" \
        -sort -sorting-method fzf \
        -qalc-binary ${pkgs.libqalculate}/bin/qalc \
        -calc-command "printf %s '{result}' | ${pkgs.wl-clipboard}/bin/wl-copy" \
        -hint-result "= " \
        -hint-welcome "5 USD to INR · 3 weeks from now · 70 kg to lb  —  Ctrl+Enter copies the result" \
        "$@"
    '';
  };
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

        # Tab labels in rofi-palette's mode switcher.
        combi.display-name = "󰍉  Search";
        window.display-name = "󱂬  Windows";
        clipboard.display-name = "󰅌  Clipboard";
        calc.display-name = "󰃬  Calc";
        emoji.display-name = "󰞅  Emoji";
        web.display-name = "󰖟  Web";
        filebrowser.display-name = "󰉋  Files";
      };
      plugins = with pkgs; [
        rofi-emoji
        rofi-calc
        glibcLocales
      ];
    };
  };

  home.packages = [ palette ];

  xdg.dataFile."rofi/themes/launcher.rasi".text = theme;
  xdg.dataFile."rofi/themes/palette.rasi".text = paletteTheme;
}

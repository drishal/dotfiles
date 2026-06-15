{ pkgs, config, ... }:

let
  # Toggle a floating watch-sync popup (bound to W in yazi). watch-sync shows
  # the live kernel disk write-back queue, so after a paste you can confirm the
  # data has actually flushed to the device, not just landed in page cache
  # (with dirty_bytes=4G a copy "finishes" into cache near-instantly).
  # pgrep/pkill keyed on the kitty --class makes it a WM-agnostic toggle and a
  # no-op-safe re-press; watch-sync only reads /proc/meminfo so closing and
  # reopening loses no state.
  watchSyncPopup = pkgs.writeShellScriptBin "watch-sync-popup" ''
    set -eu
    marker="watch-sync-float"
    if ${pkgs.procps}/bin/pgrep -f "$marker" >/dev/null 2>&1; then
      ${pkgs.procps}/bin/pkill -f "$marker" || true
    else
      ${pkgs.kitty}/bin/kitty --class "$marker" -e watch-sync >/dev/null 2>&1 &
    fi
  '';
in
{
  xdg.configFile."lf/icons".source = ./icons;

  programs.lf = {
    enable = true;
    commands = {
      dragon-out = ''%${pkgs.dragon-drop}/bin/xdragon -a -x "$fx"'';
      editor-open = ''$$EDITOR $f'';
      mkdir = ''
        ''${{
          printf "Directory Name: "
          read DIR
          mkdir $DIR
        }}
      '';
    };

    keybindings = {
      "\\\"" = "";
      o = "";
      c = "mkdir";
      "." = "set hidden!";
      "`" = "mark-load";
      "\\'" = "mark-load";
      "<enter>" = "open";

      do = "dragon-out";

      "g~" = "cd";
      gh = "cd";
      "g/" = "/";

      ee = "editor-open";
      V = ''$${pkgs.bat}/bin/bat --paging=always --theme=gruvbox "$f"'';
    };

    settings = {
      preview = true;
      hidden = true;
      drawbox = true;
      icons = true;
      ignorecase = true;
    };

    extraConfig =
      let
        previewer = pkgs.writeShellScriptBin "pv.sh" ''
          file=$1
          w=$2
          h=$3
          x=$4
          y=$5

          if [[ "$( ${pkgs.file}/bin/file -Lb --mime-type "$file")" =~ ^image ]]; then
              ${pkgs.kitty}/bin/kitty +kitten icat --silent --stdin no --transfer-mode file --place "''${w}x''${h}@''${x}x''${y}" "$file" < /dev/null > /dev/tty
              exit 1
          fi

          ${pkgs.pistol}/bin/pistol "$file"
        '';
        cleaner = pkgs.writeShellScriptBin "clean.sh" ''
          ${pkgs.kitty}/bin/kitty +kitten icat --clear --stdin no --silent --transfer-mode file < /dev/null > /dev/tty
        '';
      in
      ''
        set cleaner ${cleaner}/bin/clean.sh
        set previewer ${previewer}/bin/pv.sh
      '';
  };

  home.packages = [ pkgs.dragon-drop ];

  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";
    keymap = {
      mgr.prepend_keymap = [
        {
          on = [ "d" "o" ];
          run = ''shell --block -- ${pkgs.dragon-drop}/bin/xdragon -a -x "$@"'';
          desc = "Drag and drop via dragon";
        }
        {
          on = "W";
          run = ''shell --orphan -- ${watchSyncPopup}/bin/watch-sync-popup'';
          desc = "Toggle watch-sync (disk write-back) popup";
        }
      ];
    };
    settings = {
      manager = {
        show_hidden = false;
        sort_by = "alphabetical";
        sort_dir_first = true;
        # sort_reverse = true;
      };
    };
  };
}

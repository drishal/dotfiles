{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  c = config.lib.stylix.colors;
  repo = "${config.home.homeDirectory}/dotfiles/config/eww";

  # Stylix → eww bridge: HM owns the `colors` partial eww.scss imports, while every
  # other file is an out-of-store symlink so edits land on the next `eww reload`.
  # Mixing generated and symlinked files is why entries are linked individually.
  colorsScss = ''
    // Generated from the live Stylix scheme — edit the scheme, not this file.
    $base00: #${c.base00};
    $base01: #${c.base01};
    $base02: #${c.base02};
    $base03: #${c.base03};
    $base04: #${c.base04};
    $base05: #${c.base05};
    $base06: #${c.base06};
    $base07: #${c.base07};
    $base08: #${c.base08};
    $base09: #${c.base09};
    $base0A: #${c.base0A};
    $base0B: #${c.base0B};
    $base0C: #${c.base0C};
    $base0D: #${c.base0D};
    $base0E: #${c.base0E};
    $base0F: #${c.base0F};
  '';

  link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
in
{
  # end-rs is the eww-native notification daemon — only needed when eww is
  # the active widget stack (it owns org.freedesktop.Notifications on D-Bus).
  home.packages = with pkgs; [
    eww
    # CLI tools the widgets shell out to.
    brightnessctl
    playerctl
    networkmanagerapplet # nm-connection-editor for the network tile
    jq # workspaces/title/battery JSON shaping
    socat # event-driven Hyprland workspace/title updates (falls back to polling)
  ] ++ lib.optional (config.drishal.widgets == "eww") (
    inputs.end-rs.packages.${pkgs.stdenv.hostPlatform.system}.default
  );

  # Live-editable repo files.
  xdg.configFile."eww/eww.yuck".source = link "eww.yuck";
  xdg.configFile."eww/eww.scss".source = link "eww.scss";
  xdg.configFile."eww/scripts".source = link "scripts";
  xdg.configFile."eww/end.yuck".source = link "end.yuck";
  xdg.configFile."eww/end.scss".source = link "end.scss";

  # Stylix-generated colour partial (store-managed, regenerated each switch).
  xdg.configFile."eww/colors.scss".text = colorsScss;

  # end-rs writes a default config pointing eww_binary_path at ~/.local/bin/eww,
  # which is wrong on NixOS and makes it silently drop popups. Names must match end.yuck.
  #
  # Timeouts are all 0 so notifications with actions stay up until answered;
  # scripts/notif-reaper.py re-adds auto-dismiss for the action-less ones.
  xdg.configFile."end-rs/config.toml" = lib.mkIf (config.drishal.widgets == "eww") {
    text = ''
      eww_binary_path = "${lib.getExe pkgs.eww}"
      icon_dirs = [
          "${config.home.homeDirectory}/.nix-profile/share/icons",
          "${config.home.homeDirectory}/.nix-profile/share/pixmaps",
          "/run/current-system/sw/share/icons",
          "/run/current-system/sw/share/pixmaps",
      ]
      icon_theme = "Adwaita"
      icon_size = 64
      eww_notification_window = "notification-frame"
      eww_notification_widget = "end-notification"
      eww_notification_var = "end-notifications"
      eww_history_window = "history-frame"
      eww_history_widget = "end-history"
      eww_history_var = "end-histories"
      eww_reply_window = "reply-frame"
      eww_reply_widget = "end-reply"
      eww_reply_var = "end-replies"
      eww_reply_text = "end-reply-text"
      eww_dnd_var = "end-dnd"
      persistent_dnd = false
      max_notifications = 10
      notification_orientation = "v"
      update_history = false

      # all 0 = never auto-close; notif-reaper.py dismisses action-less ones
      # on these same urgency timeouts instead.
      [timeout]
      low = 0
      normal = 0
      critical = 0
    '';
  };
}

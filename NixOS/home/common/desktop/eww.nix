{
  config,
  lib,
  pkgs,
  ...
}:
let
  c = config.lib.stylix.colors;
  repo = "${config.home.homeDirectory}/dotfiles/config/eww";

  # Stylix → eww bridge.
  #
  # eww.scss does `@import "colors";`. Home Manager owns that one partial,
  # regenerating it from the live base16 palette on every switch, while every
  # other file in ~/.config/eww is an out-of-store symlink to the repo (so
  # layout/style edits land on the next `eww reload` without a rebuild).
  #
  # Mixing a generated file with symlinks is why we link each repo entry
  # individually rather than the whole directory.
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
  home.packages = with pkgs; [
    eww
    # CLI tools the widgets shell out to.
    brightnessctl
    playerctl
    networkmanagerapplet # nm-connection-editor for the network tile
    jq # workspaces/title/battery JSON shaping
    socat # event-driven Hyprland workspace/title updates (falls back to polling)
  ];

  # Live-editable repo files.
  xdg.configFile."eww/eww.yuck".source = link "eww.yuck";
  xdg.configFile."eww/eww.scss".source = link "eww.scss";
  xdg.configFile."eww/scripts".source = link "scripts";

  # Stylix-generated colour partial (store-managed, regenerated each switch).
  xdg.configFile."eww/colors.scss".text = colorsScss;
}

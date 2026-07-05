{
  config,
  lib,
  pkgs,
  ...
}:
let
  c = config.lib.stylix.colors;

  # Stylix → Quickshell bridge (mirrors ags.nix).
  #
  # Theme.qml reads this JSON at startup and hot-reloads on change (FileView
  # watchChanges), so picking a new Stylix scheme / font re-themes the shell on
  # the next `home-manager switch` — no QML edit, no relaunch beyond the file
  # watcher firing. It lives next to (not inside) ~/.config/quickshell because
  # that dir is an out-of-store symlink to the repo and Home Manager can't write
  # into it.
  stylixJson = builtins.toJSON {
    colors = {
      base00 = "#${c.base00}";
      base01 = "#${c.base01}";
      base02 = "#${c.base02}";
      base03 = "#${c.base03}";
      base04 = "#${c.base04}";
      base05 = "#${c.base05}";
      base06 = "#${c.base06}";
      base07 = "#${c.base07}";
      base08 = "#${c.base08}";
      base09 = "#${c.base09}";
      base0A = "#${c.base0A}";
      base0B = "#${c.base0B}";
      base0C = "#${c.base0C}";
      base0D = "#${c.base0D}";
      base0E = "#${c.base0E}";
      base0F = "#${c.base0F}";
    };
    fonts = {
      sans = config.stylix.fonts.sansSerif.name;
      mono = config.stylix.fonts.monospace.name;
    };
  };
in
{
  # Live-editable: symlink the repo config to ~/.config/quickshell so QML edits
  # take effect on the next `qs kill; qs` (or the built-in hot reload) without a
  # Home Manager rebuild.
  xdg.configFile."quickshell".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/quickshell";

  xdg.configFile."quickshell-stylix.json".text = stylixJson;

  # Quickshell + the CLI tools the QML shell shells out to (must be on PATH, not
  # just a private runtime like ags's gjs typelibs). Installed unconditionally
  # so switching drishal.widgets to "quickshell" works without a rebuild.
  home.packages = with pkgs; [
    quickshell
    cliphist # clipboard history
    wl-clipboard # wl-copy
    brightnessctl # backlight slider
    imagemagick # `magick` — clipboard image thumbnails
    curl # weather (open-meteo)
    networkmanagerapplet # nm-connection-editor (network tile/module)
    pavucontrol # audio settings (dashboard cog)
    util-linux # rfkill (airplane tile)
    libnotify
  ];
}

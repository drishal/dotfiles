{ config, lib, ... }:

# Hands the active stylix scheme to pi-coding-agent as a base16/base24 YAML.
#
# pi itself only reads JSON themes; the base16-theme extension
# (config/pi/agent/extensions/base16-theme.ts) turns every
# ~/.pi/agent/themes/<name>.yaml into <name>.json at startup. So this module
# only has to write the palette — the colour mapping lives in one place, and
# the coding agent re-themes along with everything else on a rebuild.
#
# Placement is safe under home-manager because pi only ever *reads* themes.
# Do NOT manage settings.json this way — pi rewrites it at runtime, and a
# store symlink is read-only.
#
# Activate with `"theme": "stylix"` in ~/.pi/agent/settings.json. If the theme
# is missing, pi falls back to its built-in dark theme, so the config degrades
# cleanly on a machine that has not been rebuilt yet.

let
  c = config.lib.stylix.colors;
  # base00..base0F, plus base10..base17 when the scheme is base24. Excludes
  # base16.nix's derived attributes (base00-hex, base00-rgb-r, ...).
  keys = builtins.filter (k: builtins.match "base[0-9A-F]{2}" k != null) (builtins.attrNames c);
in
{
  home.file.".pi/agent/themes/stylix.yaml".text =
    lib.concatStringsSep "\n" (
      [
        ''name: "stylix"''
        "palette:"
      ]
      ++ map (k: "  ${k}: \"${c.${k}}\"") keys
    )
    + "\n";
}

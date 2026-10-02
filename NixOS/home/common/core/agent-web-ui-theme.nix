{ config, lib, ... }:

# Hands the active stylix scheme to agent-web-ui as a base16/base24 YAML,
# the same way pi-theme.nix does for Pi. The web UI re-reads the file (it
# follows the home-manager symlink), so a rebuild re-themes open tabs the
# next time they become visible.

let
  c = config.lib.stylix.colors;
  # base00..base0F, plus base10..base17 when the scheme is base24.
  keys = builtins.filter (k: builtins.match "base[0-9A-F]{2}" k != null) (builtins.attrNames c);
  q = s: "\"${s}\"";
in
{
  xdg.configFile."agent-web-ui/theme.yaml".text =
    lib.concatStringsSep "\n" (
      [
        "name: ${q c.scheme}"
        "variant: ${q config.stylix.polarity}"
        "palette:"
      ]
      ++ map (k: "  ${k}: ${q c.${k}}") keys
      ++ [
        "fonts:"
        "  sans: ${q config.stylix.fonts.sansSerif.name}"
        "  mono: ${q config.stylix.fonts.monospace.name}"
      ]
    )
    + "\n";
}

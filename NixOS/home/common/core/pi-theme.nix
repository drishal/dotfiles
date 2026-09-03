{ config, lib, ... }:

# Generates a pi-coding-agent theme from the active stylix scheme.
#
# pi has no base16/base24 support of its own: a theme is 25 free-form `vars`
# (raw hex) plus 53 semantic slots that reference those vars by name. This maps
# whichever scheme `stylix.base16Scheme` currently points at onto that shape, so
# the coding agent re-themes along with everything else on a rebuild.
#
# Placement is safe under home-manager because pi only ever *reads* themes.
# Do NOT manage settings.json this way — remember-model.ts rewrites it at
# runtime, and a store symlink is read-only.
#
# Activate with `"theme": "stylix"` in ~/.pi/agent/settings.json. If this file
# is absent, pi silently falls back to its built-in theme (verified: unknown
# theme names exit 0 with no warning), so the config degrades cleanly on a
# machine that has not been rebuilt yet.

let
  c = config.lib.stylix.colors;

  # ── integer hex helpers ────────────────────────────────────────────────
  # base16/base24 gives no elevated surfaces or tinted status grounds, so a
  # few values are blended. Integer percentages avoid float rounding.
  digits = "0123456789abcdef";
  hexVal = ch:
    {
      "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7;
      "8" = 8; "9" = 9; "a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
      "A" = 10; "B" = 11; "C" = 12; "D" = 13; "E" = 14; "F" = 15;
    }.${ch};
  byteAt = s: i: (hexVal (builtins.substring i 1 s)) * 16 + hexVal (builtins.substring (i + 1) 1 s);
  clamp = n: if n < 0 then 0 else if n > 255 then 255 else n;
  toHex2 = n:
    let m = clamp n;
    in builtins.substring (builtins.div m 16) 1 digits
      + builtins.substring (m - (builtins.div m 16) * 16) 1 digits;

  # mix a b t  ->  a blended t% toward b. `a` and `b` are bare 6-digit hex.
  # builtins.div truncates toward zero, so nudge by half a unit first to round
  # half away from zero; without this each channel can land 1/255 low.
  mix = a: b: t:
    let
      ch = i:
        let
          d = (byteAt b i - byteAt a i) * t;
          r = if d >= 0 then d + 50 else d - 50;
        in toHex2 (byteAt a i + builtins.div r 100);
    in "#" + ch 0 + ch 2 + ch 4;

  h = v: "#" + v;

  theme = {
    "$schema" =
      "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
    name = "stylix";

    vars = {
      # ground ladder: bg -> panel -> surface -> raised
      bg = h c.base00;
      panel = h c.base01;
      surface = mix c.base01 c.base02 60;
      surfaceRaised = h c.base02;
      # base03 is the comment colour and reads as heavy chrome against base00,
      # so the border sits between selection and comment.
      border = mix c.base02 c.base03 50;
      borderMuted = h c.base02;

      # accents. base09 (orange) is warmer than the base16 convention of
      # base0D; swap it if you prefer the blue accent.
      accent = h c.base09;
      accentBright = mix c.base09 c.base07 30;
      purple = h c.base0E;
      pink = h (c.base17 or c.base0E);
      cyan = h c.base0C;
      blue = h c.base0D;
      green = h c.base0B;
      red = h c.base08;
      yellow = h c.base0A;
      orange = h c.base09;

      # ink
      text = h c.base05;
      muted = h c.base04;
      dim = h c.base03;

      # message and tool grounds
      selectedBg = h c.base02;
      userMessageBg = h c.base01;
      toolPendingBg = mix c.base00 c.base01 70;
      toolSuccessBg = mix c.base00 c.base0B 14;
      toolErrorBg = mix c.base00 c.base08 14;
      customMessageBg = mix c.base00 c.base0E 12;
    };

    # Semantic slot -> var name. Scheme-independent, so this never changes.
    colors = {
        accent = "accent";
        bashMode = "green";
        border = "border";
        borderAccent = "accent";
        borderMuted = "borderMuted";
        customMessageBg = "customMessageBg";
        customMessageLabel = "purple";
        customMessageText = "text";
        dim = "dim";
        error = "red";
        mdCode = "accentBright";
        mdCodeBlock = "text";
        mdCodeBlockBorder = "border";
        mdHeading = "accentBright";
        mdHr = "borderMuted";
        mdLink = "cyan";
        mdLinkUrl = "muted";
        mdListBullet = "accent";
        mdQuote = "muted";
        mdQuoteBorder = "accent";
        muted = "muted";
        scrollbarThumb = "selectedBg";
        selectedBg = "selectedBg";
        success = "green";
        syntaxComment = "#6b7280";
        syntaxFunction = "accentBright";
        syntaxKeyword = "pink";
        syntaxNumber = "orange";
        syntaxOperator = "text";
        syntaxPunctuation = "muted";
        syntaxString = "green";
        syntaxType = "cyan";
        syntaxVariable = "blue";
        text = "text";
        thinkingHigh = "accentBright";
        thinkingLow = "blue";
        thinkingMax = "cyan";
        thinkingMedium = "accent";
        thinkingMinimal = "dim";
        thinkingOff = "muted";
        thinkingText = "muted";
        thinkingXhigh = "#4db9cd";
        toolDiffAdded = "green";
        toolDiffContext = "muted";
        toolDiffRemoved = "red";
        toolErrorBg = "toolErrorBg";
        toolOutput = "muted";
        toolPendingBg = "toolPendingBg";
        toolSuccessBg = "toolSuccessBg";
        toolTitle = "accentBright";
        userMessageBg = "userMessageBg";
        userMessageText = "text";
        warning = "yellow";
    };
  };
in
{
  home.file.".pi/agent/themes/stylix.json".text = builtins.toJSON theme;
}

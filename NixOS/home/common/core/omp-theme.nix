{ config, lib, ... }:

# Hands the active stylix scheme to omp as a native theme.
#
# omp (and by extension Tern, which renders omp's theme) reads themes from
# ~/.omp/agent/themes/<name>.json, each with `name`, `vars`, `colors`,
# `export` and `terminal` blocks (format mirrored from omp's compiled-in
# builtins). Values reference vars by name — no hex needed outside `vars` —
# so the whole mapping lives in one place and re-themes with every rebuild.
#
# Placement is safe under home-manager because omp only ever *reads* themes;
# a missing or unreadable one falls back to its built-in dark theme, so the
# config degrades cleanly on a machine that has not been rebuilt yet.
#
# Activate with `"theme": "stylix"` (or per-appearance `theme: { dark:
# "stylix" }`) in ~/.omp/agent/config.yml. config.yml is hand-edited and is
# NOT managed here on purpose — omp rewrites it at runtime, and a store
# symlink would be read-only.

let
  c = config.lib.stylix.colors.withHashtag;

  # The 16 ANSI slots, darkest to lightest per colour family, following the
  # theme's own terminal table. Vars let `terminal.ansi` name palette entries.
  vars = {
    bg0 = c.base00; # default background
    bg1 = c.base01; # elevated background / cursorline
    bg2 = c.base02; # selection background
    bg3 = c.base02; # legacy alias kept for parity with builtins
    bg4 = c.base03; # dim
    gray = c.base04; # comment gray
    fg0 = c.base07; # lightest foreground
    fg1 = c.base05; # default foreground
    fg2 = c.base06; # mid foreground
    fg3 = c.base04; # dark foreground
    fg4 = c.base04; # darkest used foreground

    red = c.base08;
    green = c.base0B;
    yellow = c.base0A;
    blue = c.base0D;
    purple = c.base0E;
    aqua = c.base0C;
    orange = c.base09;

    # gruvbox-material has no separate brights; reuse the accents, mirroring
    # the theme's terminal table (color8-15 == color0-7).
    neutralRed = c.base08;
    neutralGreen = c.base0B;
    neutralYellow = c.base0A;
    neutralBlue = c.base0D;
    neutralPurple = c.base0E;
    neutralAqua = c.base0C;
    neutralOrange = c.base09;

    selectedBg = c.base02;
    userMsgBg = c.base10; # darker background, bg_dim
    toolPendingBg = c.base01;
    toolSuccessBg = c.base10;
    toolErrorBg = c.base11; # darkest background keeps the error card quiet
    customMsgBg = c.base01;
  };

  colors = {
    accent = "orange";
    border = "neutralBlue";
    borderAccent = "aqua";
    borderMuted = "bg2";
    success = "green";
    error = "red";
    warning = "yellow";
    muted = "gray";
    dim = "bg4";
    text = "";
    thinkingText = "gray";
    selectedBg = "selectedBg";
    userMessageBg = "userMsgBg";
    userMessageText = "";
    customMessageBg = "customMsgBg";
    customMessageText = "";
    customMessageLabel = "purple";
    toolPendingBg = "toolPendingBg";
    toolSuccessBg = "toolSuccessBg";
    toolErrorBg = "toolErrorBg";
    toolText = "";
    toolTitle = "";
    toolOutput = "gray";
    mdHeading = "yellow";
    mdLink = "aqua";
    mdLinkUrl = "bg4";
    mdCode = "purple";
    mdCodeBlock = "fg1";
    mdCodeBlockBorder = "bg2";
    mdQuote = "gray";
    mdQuoteBorder = "bg2";
    mdHr = "bg2";
    mdListBullet = "orange";
    toolDiffAdded = "green";
    toolDiffRemoved = "red";
    toolDiffContext = "gray";
    link = "aqua";
    syntaxComment = "gray";
    syntaxKeyword = "red";
    syntaxFunction = "yellow";
    syntaxVariable = "blue";
    syntaxString = "green";
    syntaxNumber = "purple";
    syntaxType = "aqua";
    syntaxOperator = "orange";
    syntaxPunctuation = "fg2";
    thinkingOff = "bg2";
    thinkingMinimal = "bg4";
    thinkingLow = "neutralBlue";
    thinkingMedium = "blue";
    thinkingHigh = "neutralPurple";
    thinkingXhigh = "purple";
    bashMode = "aqua";
    statusLineBg = c.base10; # hex: no matching var (bg_dim)
    statusLineSep = "bg2";
    statusLineModel = "purple";
    statusLinePath = "aqua";
    statusLineGitClean = "green";
    statusLineGitDirty = "yellow";
    statusLineContext = "blue";
    statusLineSpend = "aqua";
    statusLineStaged = "green";
    statusLineDirty = "yellow";
    statusLineUntracked = "blue";
    statusLineOutput = "purple";
    statusLineCost = "purple";
    statusLineSubagents = "orange";
    pythonMode = "yellow";
  };

  export = {
    pageBg = c.base10;
    cardBg = c.base00;
    infoBg = c.base01;
  };

  terminal = {
    background = "bg0";
    foreground = "fg1";
    chrome = "userMsgBg";
    widget = "bg1";
    ansi = [
      "bg0"
      "red"
      "neutralGreen"
      "neutralYellow"
      "neutralBlue"
      "neutralPurple"
      "neutralAqua"
      "fg4"
      "gray"
      "red"
      "green"
      "yellow"
      "blue"
      "purple"
      "aqua"
      "fg1"
    ];
  };

  json = lib.generators.toJSON { } {
    "$schema" =
      "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/theme-schema.json";
    name = "stylix";
    inherit vars colors export terminal;
  };
in
{
  home.file.".omp/agent/themes/stylix.json".text = json + "\n";
}

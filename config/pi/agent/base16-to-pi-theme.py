#!/usr/bin/env python3
"""
Generate a pi theme from a base16/base24 scheme.

pi has no base16 support of its own — its theme format is 25 free-form `vars`
plus 53 fixed semantic slots that reference those vars by name. This maps a
tt-schemes / stylix YAML onto that format so the terminal agent tracks whatever
`stylix.base16Scheme` is currently set to.

Usage:
    base16-to-pi-theme.py <scheme.yaml> [-o out.json] [-n name] [--accent base09]

base24 schemes use base10-base17 (extra backgrounds + bright ANSI). Plain base16
schemes only reach base0F; the missing slots are derived.
"""
import argparse, json, os, re, sys

SEMANTIC_COLORS = {
    "accent": "accent",
    "border": "border",
    "borderAccent": "accent",
    "borderMuted": "borderMuted",
    "success": "green",
    "error": "red",
    "warning": "yellow",
    "muted": "muted",
    "dim": "dim",
    "text": "text",
    "thinkingText": "muted",
    "selectedBg": "selectedBg",
    "scrollbarThumb": "selectedBg",
    "userMessageBg": "userMessageBg",
    "userMessageText": "text",
    "customMessageBg": "customMessageBg",
    "customMessageText": "text",
    "customMessageLabel": "purple",
    "toolPendingBg": "toolPendingBg",
    "toolSuccessBg": "toolSuccessBg",
    "toolErrorBg": "toolErrorBg",
    "toolTitle": "accentBright",
    "toolOutput": "muted",
    "mdHeading": "accentBright",
    "mdLink": "cyan",
    "mdLinkUrl": "muted",
    "mdCode": "accentBright",
    "mdCodeBlock": "text",
    "mdCodeBlockBorder": "border",
    "mdQuote": "muted",
    "mdQuoteBorder": "accent",
    "mdHr": "borderMuted",
    "mdListBullet": "accent",
    "toolDiffAdded": "green",
    "toolDiffRemoved": "red",
    "toolDiffContext": "muted",
    "syntaxComment": "#6b7280",
    "syntaxKeyword": "pink",
    "syntaxFunction": "accentBright",
    "syntaxVariable": "blue",
    "syntaxString": "green",
    "syntaxNumber": "orange",
    "syntaxType": "cyan",
    "syntaxOperator": "text",
    "syntaxPunctuation": "muted",
    "thinkingOff": "muted",
    "thinkingMinimal": "dim",
    "thinkingLow": "blue",
    "thinkingMedium": "accent",
    "thinkingHigh": "accentBright",
    "thinkingXhigh": "#4db9cd",
    "thinkingMax": "cyan",
    "bashMode": "green"
}

def parse_scheme(path):
    """Minimal YAML reader — these files are a flat `palette:` map of hex strings."""
    pal, meta = {}, {}
    for line in open(path, encoding="utf-8"):
        line = line.split("#")[0] if not re.match(r'\s*base\w+:', line) else line
        m = re.match(r'\s*(base[0-9A-Fa-f]{2}):\s*"?([0-9a-fA-F]{6})"?', line)
        if m:
            pal[m.group(1).lower()] = "#" + m.group(2).lower()
            continue
        m = re.match(r'\s*(name|system|variant|author):\s*"?([^"#\n]+?)"?\s*$', line)
        if m:
            meta[m.group(1)] = m.group(2).strip()
    return pal, meta

def rgb(h):  return tuple(int(h.lstrip("#")[i:i+2], 16) for i in (0, 2, 4))
def hexs(t): return "#%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in t)
def mix(a, b, t):
    """Blend a toward b by t (0..1)."""
    return hexs(tuple(x + (y - x) * t for x, y in zip(rgb(a), rgb(b))))

def build(pal, name, accent_key):
    g = pal.get
    b00, b05, b07 = g("base00"), g("base05"), g("base07", g("base05"))
    if not (b00 and b05):
        sys.exit("scheme is missing base00/base05")

    # base24 extras; derive them when the scheme is plain base16.
    b01 = g("base01", mix(b00, b05, 0.08))
    b02 = g("base02", mix(b00, b05, 0.16))
    b03 = g("base03", mix(b00, b05, 0.34))
    b04 = g("base04", mix(b00, b05, 0.62))
    accent = g(accent_key) or g("base0d") or b05
    purple = g("base0e", b05)

    vars_ = {
        # ── ground ladder: bg -> panel -> surface -> raised -> border
        "bg":            b00,
        "panel":         b01,
        "surface":       mix(b01, b02, 0.6),
        "surfaceRaised": b02,
        # base03 is the comment colour and reads as heavy chrome against base00;
        # sit the border between selection and comment instead.
        "border":        mix(b02, b03, 0.5),
        "borderMuted":   b02,
        # ── accents
        "accent":        accent,
        "accentBright":  mix(accent, b07, 0.30),
        "purple":        purple,
        "pink":          g("base17", purple),      # base24 bright purple; falls back
        "cyan":          g("base0c", b05),
        "blue":          g("base0d", b05),
        "green":         g("base0b", b05),
        "red":           g("base08", b05),
        "yellow":        g("base0a", b05),
        "orange":        g("base09", g("base0a", b05)),
        # ── ink
        "text":          b05,
        "muted":         b04,
        "dim":           b03,
        # ── message / tool grounds. base16 defines no tinted backgrounds, so
        #    these are the base ground pulled a little toward the status hue.
        "selectedBg":      b02,
        "userMessageBg":   b01,
        "toolPendingBg":   mix(b00, b01, 0.7),
        "toolSuccessBg":   mix(b00, g("base0b", b05), 0.14),
        "toolErrorBg":     mix(b00, g("base08", b05), 0.14),
        "customMessageBg": mix(b00, purple, 0.12),
    }
    return {
        "$schema": "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json",
        "name": name,
        "vars": vars_,
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("scheme")
    ap.add_argument("-o", "--out")
    ap.add_argument("-n", "--name")
    ap.add_argument("--accent", default="base09",
                    help="palette key used as the UI accent (default base09/orange; "
                         "base0d is the base16 convention)")
    a = ap.parse_args()

    pal, meta = parse_scheme(a.scheme)
    name = a.name or re.sub(r"[^a-z0-9]+", "-", meta.get("name", "custom").lower()).strip("-")
    theme = build(pal, name, a.accent.lower())

    # The 53 semantic slots reference vars by name, so they are scheme-independent.
    theme["colors"] = SEMANTIC_COLORS

    out = a.out or os.path.expanduser(f"~/.pi/agent/themes/{name}.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(theme, f, indent="\t")
        f.write("\n")
    print(f"{meta.get('system','base16')} '{meta.get('name',name)}' -> {out}")
    print(f"  {len(pal)} palette entries -> {len(theme['vars'])} vars + {len(theme['colors'])} colors")
    print(f"  bg {theme['vars']['bg']}  accent {theme['vars']['accent']}  text {theme['vars']['text']}")

main()

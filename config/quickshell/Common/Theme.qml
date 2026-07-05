pragma Singleton

// Colour + font tokens — the Stylix bridge (mirrors the ags shell's
// _colors.scss / ags-stylix.css mechanism).
//
// quickshell.nix writes the live base16 palette + Stylix fonts to
// ~/.config/quickshell-stylix.json (a sibling of the symlinked config dir, so
// it doesn't fight the out-of-store symlink). We read it here and expose the
// slots as `color` properties so the whole shell re-themes on a Stylix switch
// without touching QML. Missing file (running straight from the repo) → the
// baked gruvbox-material fallback below, matching the current live scheme.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── raw base16 slots (fallback = live gruvbox-material hard-dark) ──────
    property color base00: "#1d2021"
    property color base01: "#282828"
    property color base02: "#3c3836"
    property color base03: "#7c6f64"
    property color base04: "#928374"
    property color base05: "#d4be98"
    property color base06: "#ddc7a1"
    property color base07: "#ebdbb2"
    property color base08: "#ea6962"
    property color base09: "#e78a4e"
    property color base0A: "#d8a657"
    property color base0B: "#a9b665"
    property color base0C: "#89b482"
    property color base0D: "#7daea3"
    property color base0E: "#d3869b"
    property color base0F: "#bd6f3e"

    // ── semantic aliases (mirror _colors.scss) ────────────────────────────
    readonly property color card: base01 // elevated surface
    readonly property color cardHi: base02 // hover / pressed
    readonly property color ink: base05 // primary text
    readonly property color inkDim: base04 // secondary text
    readonly property color accent: base0D // accent
    readonly property color accentInk: base00 // text on accent
    // floating bar island — a touch below the bg (shade(base00, 0.92))
    readonly property color island: Qt.darker(base00, 1.12)
    // urgent-workspace surface — translucent red over the island
    readonly property color alertBg: Qt.rgba(base08.r, base08.g, base08.b, 0.25)
    readonly property color alertBgHi: Qt.rgba(base08.r, base08.g, base08.b, 0.35)

    // ── fonts ──────────────────────────────────────────────────────────────
    property string fontSans: "Google Sans"
    property string fontMono: "Maple Mono NF"

    // ── design tokens (from main.scss) ─────────────────────────────────────
    readonly property int radius: 18
    readonly property int radiusSm: 14
    readonly property int gap: 10

    // ── Stylix JSON bridge ─────────────────────────────────────────────────
    function applyJson(text) {
        try {
            const d = JSON.parse(text);
            const c = d.colors || {};
            for (const k of Object.keys(c))
                if (root.hasOwnProperty(k))
                    root[k] = c[k];
            if (d.fonts) {
                if (d.fonts.sans)
                    root.fontSans = d.fonts.sans;
                if (d.fonts.mono)
                    root.fontMono = d.fonts.mono;
            }
        } catch (e) {
            // keep baked fallback
        }
    }

    FileView {
        id: stylixFile
        path: Quickshell.env("HOME") + "/.config/quickshell-stylix.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyJson(stylixFile.text())
    }
}

pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

// Standalone theme shim for the Hermes desktop app.
//
// The chat components were written against DMS's Theme singleton (Material You
// tokens). This reimplements the same token surface with a static
// gruvbox-material dark palette so the app renders identically without DMS.
//
// To re-theme: change the base palette below. Every derived token (hover,
// pressed, alpha fills) is computed from it, so the accents stay coherent.
QtObject {
    id: theme

    // ── Base palette (gruvbox-material dark, medium) ───────────
    readonly property color _bg0:  "#282828"
    readonly property color _bg1:  "#32302f"
    readonly property color _bg2:  "#3c3836"
    readonly property color _bg3:  "#45403d"
    readonly property color _bg4:  "#504945"
    readonly property color _fg0:  "#d4be98"
    readonly property color _fgDim: "#a89984"
    readonly property color _gray: "#928374"

    readonly property color _blue:   "#7daea3"
    readonly property color _aqua:   "#89b482"
    readonly property color _purple: "#d3869b"
    readonly property color _red:    "#ea6962"
    readonly property color _green:  "#a9b665"
    readonly property color _yellow: "#d8a657"

    // ── Spacing & sizing ───────────────────────────────────────
    readonly property int spacingXS: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 16
    readonly property int iconSize: 20
    readonly property int cornerRadius: 12

    readonly property int fontSizeSmall: 12
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 18

    // ── Text ───────────────────────────────────────────────────
    readonly property color surfaceText: _fg0
    readonly property color surfaceTextMedium: _fgDim
    readonly property color surfaceVariantText: _gray

    // ── Surfaces ───────────────────────────────────────────────
    readonly property color surfaceContainer: _bg1
    readonly property color surfaceContainerHigh: _bg2
    readonly property color surfaceContainerHighest: _bg3
    readonly property color surfaceVariant: _bg4
    readonly property color surfaceVariantAlpha: Qt.rgba(_bg4.r, _bg4.g, _bg4.b, 0.35)
    readonly property color surfaceHover: Qt.rgba(1, 1, 1, 0.06)

    // ── Primary accent ─────────────────────────────────────────
    readonly property color primary: _blue
    readonly property color primaryText: _bg0
    readonly property color onPrimary: _bg0
    readonly property color primaryPressed: Qt.darker(_blue, 1.2)
    readonly property color primaryBackground: Qt.rgba(_blue.r, _blue.g, _blue.b, 0.15)
    readonly property color primarySelected: Qt.rgba(_blue.r, _blue.g, _blue.b, 0.22)

    // ── Semantic accents ───────────────────────────────────────
    readonly property color tertiary: _purple
    readonly property color error: _red
    readonly property color errorPressed: Qt.rgba(_red.r, _red.g, _red.b, 0.25)
    readonly property color success: _green
    readonly property color warning: _yellow

    // ── Outlines ───────────────────────────────────────────────
    readonly property color outlineVariant: _bg3
    readonly property color outlineMedium: _bg4
}

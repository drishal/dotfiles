pragma ComponentBehavior: Bound
import QtQuick
import qs.Common

// Nerd Font glyph. `inkCentered` positions by the painted ink rather than the
// advance box — Nerd Font glyphs overflow their box and lean right otherwise.
Text {
    id: root

    property bool inkCentered: false

    color: Theme.inkDim
    font.family: Theme.fontMono
    font.pixelSize: 14

    x: inkCentered && parent ? parent.width / 2 - (tm.tightBoundingRect.x + tm.tightBoundingRect.width / 2) : x

    Behavior on color {
        CAnim {}
    }

    TextMetrics {
        id: tm
        font: root.font
        text: root.text
    }
}

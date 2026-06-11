import QtQuick
import qs.Common

// Stand-in for DMS's DankIcon. Renders a Material Symbols Rounded glyph by
// ligature name (e.g. "smart_toy", "search"), using the font bundled under
// ../assets/fonts. Same property surface the chat components rely on:
//   name (ligature), size, color, filled.
Item {
    id: root

    property alias name: icon.text
    property alias size: icon.font.pixelSize
    property alias color: icon.color
    property bool filled: false
    property int weight: filled ? 500 : 400

    implicitWidth: Math.round(size)
    implicitHeight: Math.round(size)

    FontLoader {
        id: materialSymbolsFont
        source: Qt.resolvedUrl("../../assets/fonts/MaterialSymbolsRounded.ttf")
    }

    Text {
        id: icon
        anchors.fill: parent
        font.family: materialSymbolsFont.name
        font.pixelSize: Math.round(Theme.fontSizeMedium)
        font.weight: root.weight
        font.hintingPreference: Font.PreferNoHinting
        color: Theme.surfaceText
        renderType: Text.NativeRendering
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        font.variableAxes: ({
            "FILL": root.filled ? 1 : 0,
            "GRAD": -25,
            "opsz": 24,
            "wght": root.weight
        })
    }
}

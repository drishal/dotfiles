pragma ComponentBehavior: Bound
import QtQuick
import qs.Common

// Text with the shell's defaults baked in. `animate` dips to transparent on text
// change, so it suits jittery values (percentages), not a clock that reads as a blink.
Text {
    id: root

    property bool animate: false

    color: Theme.ink
    font.family: Theme.fontSans
    font.pixelSize: 13
    textFormat: Text.PlainText
    // FreeType + fontconfig hinting; the distance-field default is soft at bar sizes.
    renderType: Text.NativeRendering

    Behavior on color {
        CAnim {}
    }

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.FastEffects
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }
}

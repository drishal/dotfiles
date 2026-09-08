import QtQuick
import qs.Common

// Text with the shell's defaults baked in. `animate` cross-fades on text
// change, which suits values that tick (clock, percentages) rather than labels.
Text {
    id: root

    property bool animate: false

    color: Theme.ink
    font.family: Theme.fontSans
    font.pixelSize: 13
    textFormat: Text.PlainText

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

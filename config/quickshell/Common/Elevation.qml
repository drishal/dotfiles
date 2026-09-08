import QtQuick
import QtQuick.Effects
import qs.Common

// Material elevation as a drop shadow behind a rounded rect. Place it as a
// sibling *before* the surface it lifts, filling the same geometry; `level`
// animates, so a card can rise on hover.
RectangularShadow {
    id: root

    property int level: 1
    property real dp: [0, 1, 3, 6, 8, 12][Math.max(0, Math.min(5, level))]

    color: Qt.rgba(0, 0, 0, 0.55)
    blur: Math.pow(dp * 5, 0.7)
    spread: -dp * 0.3 + Math.pow(dp * 0.1, 2)
    offset.y: dp / 2

    Behavior on dp {
        Anim {
            type: Anim.SlowEffects
        }
    }
}

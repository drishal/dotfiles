pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Services

// Spectrum bars rising from the bottom edge, fed by Cava. Holds a Cava ref
// only while `active` (visible and something is playing).
Item {
    id: root

    property bool active: false
    property color color: Theme.accent
    property real spacing: 3

    readonly property bool live: active && visible

    onLiveChanged: live ? Cava.addRef() : Cava.removeRef()
    Component.onDestruction: if (live)
        Cava.removeRef()

    opacity: live ? 1 : 0
    Behavior on opacity {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Row {
        anchors.fill: parent
        spacing: root.spacing

        Repeater {
            model: Cava.bars

            delegate: Item {
                id: bar

                required property int index

                width: (root.width - root.spacing * (Cava.bars - 1)) / Cava.bars
                height: root.height

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * (Cava.values[bar.index] ?? 0) / 100
                    radius: Math.min(width, height) / 2
                    visible: height > 1
                    color: root.color
                }
            }
        }
    }
}

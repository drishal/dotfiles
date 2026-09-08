import QtQuick
import qs.Common
import qs.Services

// Base for every panel hosted inside a shell surface. Panels are plain Items,
// not windows — the surface never resizes, so a panel can animate its geometry
// freely without a compositor round-trip per frame.
//
// Fade and springy motion are split on purpose: `fade` uses a curve that cannot
// overshoot, so `visible` never flickers off and back at the end of a close,
// while `pop` carries the overshoot that makes the panel feel physical.
Item {
    id: root

    // Popups key. Empty means the panel drives `shown` itself (transient OSDs).
    property string name: ""
    required property string screenName
    property bool shown: name !== "" && Popups.isOpen(name, screenName)
    property bool keyboard: false
    property int slideFrom: Qt.TopEdge
    property real slideDistance: 26

    property real fade: shown ? 1 : 0
    property real pop: shown ? 1 : 0

    readonly property real slideX: slideFrom === Qt.LeftEdge ? -(1 - pop) * slideDistance : slideFrom === Qt.RightEdge ? (1 - pop) * slideDistance : 0
    readonly property real slideY: slideFrom === Qt.TopEdge ? -(1 - pop) * slideDistance : slideFrom === Qt.BottomEdge ? (1 - pop) * slideDistance : 0

    function close() {
        if (name)
            Popups.close(name, screenName);
    }

    visible: fade > 0.001
    opacity: fade
    scale: 0.96 + 0.04 * pop
    transform: Translate {
        x: root.slideX
        y: root.slideY
    }

    focus: shown && keyboard
    Keys.onEscapePressed: root.close()

    Behavior on fade {
        Anim {
            type: Anim.Emphasized
            duration: Theme.animDurations[Anim.DefaultEffects]
        }
    }
    Behavior on pop {
        Anim {
            type: Anim.DefaultSpatial
        }
    }
}

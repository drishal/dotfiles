pragma ComponentBehavior: Bound
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

    // Optional container transform: instead of fading in place, the panel grows
    // out of this rect (given in the panel's own coordinate space — typically
    // the bar item that opened it). Panels that use it bind their card to
    // morphX/Y/W/H and their body to contentFade, rather than filling the panel.
    property rect morphFrom: Qt.rect(0, 0, 0, 0)
    readonly property bool morphing: morphFrom.width > 0

    property real fade: shown ? 1 : 0
    property real pop: shown ? 1 : 0

    readonly property real slideX: slideFrom === Qt.LeftEdge ? -(1 - pop) * slideDistance : slideFrom === Qt.RightEdge ? (1 - pop) * slideDistance : 0
    readonly property real slideY: slideFrom === Qt.TopEdge ? -(1 - pop) * slideDistance : slideFrom === Qt.BottomEdge ? (1 - pop) * slideDistance : 0

    readonly property real morphX: morphing ? morphFrom.x * (1 - pop) : 0
    readonly property real morphY: morphing ? morphFrom.y * (1 - pop) : 0
    readonly property real morphW: morphing ? morphFrom.width + (width - morphFrom.width) * pop : width
    readonly property real morphH: morphing ? morphFrom.height + (height - morphFrom.height) * pop : height
    // Body waits until the container has most of its size, so text does not
    // appear crammed into a sliver mid-expansion.
    readonly property real contentFade: morphing ? Math.max(0, Math.min(1, (pop - 0.3) / 0.5)) : 1

    function close() {
        if (name)
            Popups.close(name, screenName);
    }

    visible: fade > 0.001
    opacity: fade
    // A morphing panel animates its own geometry, so it must not also be
    // scaled or slid.
    scale: morphing ? 1 : 0.96 + 0.04 * pop
    transform: Translate {
        x: root.morphing ? 0 : root.slideX
        y: root.morphing ? 0 : root.slideY
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

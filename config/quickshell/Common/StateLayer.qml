pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs.Common

// Material state layer: a hover tint plus a press ripple that grows from the
// actual click point. Drop it in as the last child of any rounded surface — it
// picks up the parent's radius and fills it, so buttons need no hover wiring.
MouseArea {
    id: root

    property color color: Theme.ink
    property bool disabled: false
    property real hoverOpacity: 0.10
    property real pressOpacity: 0.13
    // qmllint disable missing-property
    property real radius: parent?.radius ?? 0
    // qmllint enable missing-property

    // Farthest corner from the press point — the ripple has to reach it.
    readonly property real endRadius: {
        const d = (x, y) => Math.sqrt((ripple.px - x) ** 2 + (ripple.py - y) ** 2);
        return Math.max(d(0, 0), d(width, 0), d(0, height), d(width, height));
    }

    anchors.fill: parent
    enabled: !disabled
    hoverEnabled: true
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor

    onPressed: event => {
        ripple.px = event.x;
        ripple.py = event.y;
        ripple.size = 0;
        ripple.opacity = root.pressOpacity;
        grow.restart();
    }
    onReleased: fade.restart()
    onCanceled: fade.restart()

    ClippingRectangle {
        anchors.fill: parent
        color: "transparent"
        radius: root.radius

        Rectangle {
            anchors.fill: parent
            color: root.color
            opacity: root.containsMouse && !root.disabled ? root.hoverOpacity : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Rectangle {
            id: ripple

            property real px: 0
            property real py: 0
            property real size: 0

            x: px - size
            y: py - size
            width: size * 2
            height: size * 2
            radius: size
            color: root.color
            opacity: 0
        }
    }

    Anim {
        id: grow

        target: ripple
        property: "size"
        to: root.endRadius
        type: Anim.SlowEffects
        duration: Theme.animDurations[Anim.SlowEffects] * 1.6
    }

    Anim {
        id: fade

        target: ripple
        property: "opacity"
        to: 0
        type: Anim.SlowEffects
    }
}

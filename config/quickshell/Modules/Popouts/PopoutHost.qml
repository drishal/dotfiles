import QtQuick
import qs.Common
import qs.Services

// One popout container shared by every bar status item. Moving between items
// morphs it rather than closing and reopening: a spring drives x/width/height
// (so retargeting mid-flight keeps its velocity) while the bodies cross-fade.
//
// All bodies stay instantiated. Building one on demand meant the swap paid for
// constructing it — WifiDetail plus an nmcli spawn — right in the middle of the
// morph, and the target size was not known until after that, so the resize and
// the fade ran one after the other instead of together. Idle cost is nil
// because each body only does work while `live`.

Item {
    id: root

    required property string screenName

    // Sits flush against the island's bottom edge so there is no dead strip
    // between bar and popout for the pointer to fall through.
    readonly property int barBottom: 36
    readonly property int lift: 4

    property string current: ""
    property real anchorX: 0

    readonly property bool open: current !== ""
    property bool snapNext: true

    // Held through a close so the frame keeps its size while fading out.
    property string lastName: ""
    onCurrentChanged: if (current !== "")
        lastName = current

    readonly property Item activeBody: {
        const n = root.open ? root.current : root.lastName;
        if (n === "network")
            return netBody;
        if (n === "stats")
            return statsBody;
        if (n === "battery")
            return batteryBody;
        return null;
    }

    readonly property real wantW: activeBody ? activeBody.implicitWidth : 0
    readonly property real wantH: activeBody ? activeBody.implicitHeight : 0
    readonly property real wantX: Math.max(8, Math.min(root.width - wantW - 8, anchorX - wantW / 2))

    // The input region follows the *target*, not the animated geometry: it then
    // changes twice per interaction instead of once per frame, and the popout is
    // hoverable for the whole morph rather than only once it has caught up.
    readonly property real maskX: wantX
    readonly property real maskY: barBottom
    readonly property real maskW: frame.visible ? wantW : 0
    readonly property real maskH: frame.visible ? wantH + lift : 0

    function request(name, cx) {
        closeTimer.stop();
        anchorX = cx;
        current = name;
    }
    function release() {
        closeTimer.restart();
    }
    function sync() {
        spring.retarget(wantX, wantW, wantH);
        if (snapNext && wantW > 0) {
            spring.settle();
            snapNext = false;
        }
    }

    onWantWChanged: sync()
    onWantHChanged: sync()
    onWantXChanged: sync()
    onOpenChanged: if (!open)
        snapNext = true

    Timer {
        id: closeTimer

        interval: 180
        onTriggered: root.current = ""
    }

    Spring {
        id: spring

        // Just under critical (2·√560 ≈ 47) — enough overshoot to feel alive,
        // tight enough not to wobble.
        stiffness: 560
        damping: 42
    }

    Item {
        id: frame

        property real fade: root.open ? 1 : 0

        x: spring.x1
        y: root.barBottom
        width: spring.w
        height: spring.h + root.lift
        visible: fade > 0.001
        opacity: fade
        scale: 0.97 + 0.03 * fade
        transformOrigin: Item.Top

        Behavior on fade {
            Anim {
                type: Anim.Emphasized
                duration: Theme.animDurations[Anim.DefaultEffects]
            }
        }

        Elevation {
            anchors.fill: card
            radius: card.radius
            level: 3
        }

        StyledRect {
            id: card

            anchors.fill: parent
            anchors.topMargin: root.lift
            radius: Theme.radius
            color: Theme.base00
            border.width: 1
            border.color: Theme.base02
            clip: true

            // Bodies overlap and cross-fade; the shrinking card clips the
            // outgoing one, which is what sells the morph.
            NetPopout {
                id: netBody

                live: root.current === "network"
                opacity: root.current === "network" ? 1 : 0
                visible: opacity > 0.001

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
            StatsPopout {
                id: statsBody

                live: root.current === "stats"
                opacity: root.current === "stats" ? 1 : 0
                visible: opacity > 0.001

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
            BatteryPopout {
                id: batteryBody

                opacity: root.current === "battery" ? 1 : 0
                visible: opacity > 0.001

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: closeTimer.stop()
            onExited: root.release()
        }
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Services

// One popout container shared by every bar status item. Opened by left-clicking
// an item — hovering is too easy to trigger by accident on a bar you sweep the
// pointer across. Clicking a different item morphs the popout across rather than
// closing and reopening: a spring drives x/width/height (so retargeting
// mid-flight keeps its velocity) while the bodies cross-fade.
//
// The popout is a drawer: its surface is painted by Backdrop, joined to the
// island, and grows down out of the bar. Horizontal speed squashes and
// stretches it — wider and shallower while it travels, settling as it stops.
//
// All bodies stay instantiated. Building one on demand meant the swap paid for
// constructing it — WifiDetail plus an nmcli spawn — right in the middle of the
// morph, and the target size was not known until after that, so the resize and
// the fade ran one after the other instead of together. Idle cost is nil
// because each body only does work while `live`.

Item {
    id: root

    required property string screenName

    readonly property int barBottom: Theme.barHeight

    // Bodies overlap and cross-fade; the shrinking surface clips the outgoing
    // one. Each is pinned to the surface's bottom edge until it fits, so it
    // slides out of the bar instead of being uncovered in place.
    component BodySlot: Item {
        required property string bodyKey
        readonly property bool active: root.shownName === bodyKey

        width: childrenRect.width
        height: childrenRect.height
        y: Math.round(Math.min(0, spring.h - height))
        opacity: active ? 1 : 0
        visible: opacity > 0.001

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    property string current: ""
    property real anchorX: 0

    // A panel owns the screen while it is open, so the popout stands down —
    // otherwise clicking the CPU/RAM cluster leaves its popout sitting under
    // the process panel that just grew out of the same spot.
    readonly property bool blocked: Popups.current(screenName) !== ""

    readonly property bool open: current !== "" && !blocked

    onBlockedChanged: if (blocked)
        current = ""

    // Held through a close so the outgoing body stays put while it retracts.
    property string lastName: ""
    onCurrentChanged: if (current !== "")
        lastName = current
    readonly property string shownName: open ? current : lastName

    readonly property Item activeBody: {
        if (shownName === "network")
            return netBody;
        if (shownName === "stats")
            return statsBody;
        if (shownName === "battery")
            return batteryBody;
        return null;
    }

    readonly property real wantW: activeBody ? activeBody.implicitWidth : 0
    readonly property real wantH: activeBody ? activeBody.implicitHeight : 0
    readonly property real wantX: Math.max(Theme.islandInset, Math.min(root.width - wantW - Theme.islandInset, anchorX - wantW / 2))

    // ── surface, read by Backdrop ──────────────────────────────────────────
    readonly property real deform: Math.min(0.06, Math.abs(spring.vx) * 1e-5)
    // Whole pixels, for the same reason as Panel: native text steps by pixel.
    readonly property real surfaceX: Math.round(spring.x1 - spring.w * deform / 2)
    readonly property real surfaceY: barBottom
    readonly property real surfaceW: Math.round(spring.w * (1 + deform))
    readonly property real surfaceH: Math.round(Math.max(0, spring.h) * (1 - deform / 2))
    readonly property real radius: Theme.radius

    // The input region follows the *target*, not the animated geometry: it then
    // changes twice per interaction instead of once per frame, and the popout is
    // clickable for the whole morph rather than only once it has caught up.
    readonly property real maskX: wantX
    readonly property real maskY: barBottom
    readonly property real maskW: open ? wantW : 0
    readonly property real maskH: open ? wantH : 0

    function toggle(name, cx) {
        if (blocked)
            return;
        if (current === name) {
            current = "";
            return;
        }
        anchorX = cx;
        current = name;
    }
    function close() {
        current = "";
    }
    function sync() {
        // Opening from nothing: appear in place and only grow downwards.
        if (open && spring.h < 1) {
            spring.x1 = wantX;
            spring.w = wantW;
            spring.vx = spring.vw = 0;
        }
        spring.retarget(wantX, wantW, open ? wantH : 0);
    }

    onWantWChanged: sync()
    onWantHChanged: sync()
    onWantXChanged: sync()
    onOpenChanged: sync()
    Component.onCompleted: sync()

    Spring {
        id: spring

        // Just under critical (2·√560 ≈ 47) — enough overshoot to feel alive,
        // tight enough not to wobble.
        stiffness: 560
        damping: 42
    }

    Item {
        id: frame

        x: root.surfaceX
        y: root.barBottom
        width: root.surfaceW
        height: root.surfaceH
        visible: height > 0.5
        clip: true

        Item {
            width: spring.w
            height: Math.max(0, spring.h)
            transform: Scale {
                origin.x: spring.w / 2
                xScale: 1 + root.deform
                yScale: 1 - root.deform / 2
            }

            BodySlot {
                bodyKey: "network"

                NetPopout {
                    id: netBody

                    live: root.current === "network"
                }
            }
            BodySlot {
                bodyKey: "stats"

                StatsPopout {
                    id: statsBody

                    live: root.current === "stats"
                }
            }
            BodySlot {
                bodyKey: "battery"

                BatteryPopout {
                    id: batteryBody
                }
            }
        }
    }
}

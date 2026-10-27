pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Services

// Base for every panel hosted inside a shell surface. Panels are plain Items,
// not windows — the surface never resizes, so a panel can animate its geometry
// freely without a compositor round-trip per frame.
//
// An `attached` panel is a drawer hanging from the bar: it draws no surface of
// its own — Backdrop paints `surfaceX/W/H` joined to the island — and its body
// slides out from behind the bar, clipped at the seam. Surface edges and the
// body offset are whole pixels: text is rendered natively (pixel-snapped), so
// a fractional surface edge sliding against stepping text reads as jitter.
// A floating panel (attached: false) draws its own card and fades, scales and
// slides in from `slideFrom`.
Item {
    id: root

    // Popups key. Empty means the panel drives `shown` itself (transient OSDs).
    property string name: ""
    required property string screenName
    property bool shown: name !== "" && Popups.isOpen(name, screenName)
    property bool keyboard: false
    property bool attached: true
    property real radius: Theme.radius
    property int slideFrom: Qt.TopEdge
    property real slideDistance: 26

    // Optional container transform: the surface grows out of this rect (in the
    // panel's own coordinates — typically the bar item that opened it) instead
    // of spanning the panel's full width from the start.
    property rect morphFrom: Qt.rect(0, 0, 0, 0)
    readonly property bool morphing: morphFrom.width > 0

    default property alias content: inner.data

    property real fade: shown ? 1 : 0
    property real pop: 0

    // ── surface geometry, panel coordinates (read by Backdrop) ─────────────
    readonly property real reveal: Math.max(0, pop)
    readonly property real surfaceX: morphing ? Math.round(morphFrom.x * (1 - Math.min(1, reveal))) : 0
    readonly property real surfaceY: 0
    readonly property real surfaceW: morphing ? Math.round(morphFrom.width + (width - morphFrom.width) * Math.min(1, reveal)) : width
    readonly property real surfaceH: attached ? Math.round(height * reveal) : height
    // Body waits until the surface has most of its size, so text does not
    // appear crammed into a sliver mid-expansion.
    readonly property real contentFade: Math.max(0, Math.min(1, (reveal - (morphing ? 0.3 : 0.1)) / 0.5))

    readonly property real slideX: slideFrom === Qt.LeftEdge ? -(1 - pop) * slideDistance : slideFrom === Qt.RightEdge ? (1 - pop) * slideDistance : 0
    readonly property real slideY: slideFrom === Qt.TopEdge ? -(1 - pop) * slideDistance : slideFrom === Qt.BottomEdge ? (1 - pop) * slideDistance : 0

    function close() {
        if (name)
            Popups.close(name, screenName);
    }

    // Drawers decelerate in without overshoot — a bounce on a tall surface
    // reads as wobble — and accelerate back into the bar. Floating panels keep
    // the springy spatial curve.
    onShownChanged: {
        popAnim.stop();
        popAnim.to = shown ? 1 : 0;
        popAnim.type = shown ? (attached ? Anim.Emphasized : Anim.DefaultSpatial) : (attached ? Anim.EmphasizedAccel : Anim.StandardAccel);
        popAnim.start();
    }
    Component.onCompleted: pop = shown ? 1 : 0

    visible: attached ? surfaceH > 0.5 : fade > 0.001
    opacity: attached ? 1 : fade
    scale: attached ? 1 : 0.96 + 0.04 * pop
    transform: Translate {
        x: root.attached ? 0 : root.slideX
        y: root.attached ? 0 : root.slideY
    }

    focus: shown && keyboard
    Keys.onEscapePressed: root.close()

    Anim {
        id: popAnim

        target: root
        property: "pop"
    }
    Behavior on fade {
        Anim {
            type: Anim.Emphasized
            duration: Theme.animDurations[Anim.DefaultEffects]
        }
    }

    // Clips the body to the surface: at the bar seam while it slides out, and
    // to the growing rect while it morphs.
    Item {
        id: clipper

        x: root.attached ? root.surfaceX : 0
        width: root.attached ? root.surfaceW : root.width
        height: root.attached ? Math.min(root.surfaceH, root.height) : root.height
        clip: root.attached

        Item {
            id: inner

            x: -clipper.x
            // Pinned to the surface's bottom edge until it has fully emerged.
            y: root.attached ? Math.min(0, root.surfaceH - root.height) : 0
            width: root.width
            height: root.height
            opacity: root.attached ? root.contentFade : 1

        }
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import qs.Common

// Marquee for text that outgrows its slot: holds at the start, creeps to the
// end, holds, then runs back. Falls back to eliding when it fits, and stops
// entirely when off-screen so an idle bar costs nothing.
Item {
    id: root

    property alias text: label.text
    property alias font: label.font
    property alias color: label.color
    property bool active: true
    property real holdMs: 1800
    property real pxPerMs: 0.022
    property real leftPadding: 0

    // Natural text width, independent of the slot width — safe to size the
    // slot from without a binding loop, since the label never wraps.
    readonly property real textWidth: label.implicitWidth

    readonly property bool overflowing: label.implicitWidth + leftPadding > width
    readonly property bool scrolling: overflowing && active && visible
    readonly property real maxOffset: Math.max(0, label.implicitWidth + leftPadding - width)

    property real offset: 0

    readonly property int travelMs: Math.max(1, Math.round(maxOffset / pxPerMs))

    onScrollingChanged: if (!scrolling)
        offset = 0

    clip: true
    implicitHeight: label.implicitHeight

    StyledText {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        width: root.overflowing ? implicitWidth : root.width - root.leftPadding
        x: root.leftPadding - Math.round(root.offset)
        wrapMode: Text.NoWrap
        elide: root.overflowing ? Text.ElideNone : Text.ElideRight
    }

    // Declarative rather than a per-frame JS callback: the animation driver
    // runs this in C++, so a long window title costs no script execution.
    SequentialAnimation {
        running: root.scrolling
        loops: Animation.Infinite

        PauseAnimation {
            duration: root.holdMs
        }
        NumberAnimation {
            target: root
            property: "offset"
            from: 0
            to: root.maxOffset
            duration: root.travelMs
            easing.type: Easing.Linear
        }
        PauseAnimation {
            duration: root.holdMs
        }
        NumberAnimation {
            target: root
            property: "offset"
            from: root.maxOffset
            to: 0
            duration: root.travelMs
            easing.type: Easing.Linear
        }
    }
}

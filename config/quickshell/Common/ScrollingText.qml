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
    property int direction: 1
    property real holdLeft: holdMs

    function reset() {
        offset = 0;
        direction = 1;
        holdLeft = holdMs;
    }

    onScrollingChanged: if (!scrolling)
        reset()
    onTextChanged: reset()

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

    FrameAnimation {
        running: root.scrolling

        onTriggered: {
            const ms = frameTime * 1000;
            if (root.holdLeft > 0) {
                root.holdLeft -= ms;
                return;
            }
            const next = root.offset + root.direction * ms * root.pxPerMs;
            if (next >= root.maxOffset) {
                root.offset = root.maxOffset;
                root.direction = -1;
                root.holdLeft = root.holdMs;
            } else if (next <= 0) {
                root.offset = 0;
                root.direction = 1;
                root.holdLeft = root.holdMs;
            } else {
                root.offset = next;
            }
        }
    }
}

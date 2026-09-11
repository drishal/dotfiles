pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.Common

// Hours stacked over minutes in two tones. Tight bounding metrics strip the
// font's leading, so the two lines sit flush instead of a line-height apart.
Item {
    id: root

    property real sizeScale: 1

    readonly property int px: Math.round(132 * sizeScale)
    readonly property int lead: Math.round(px * 0.09)

    // tightBoundingRect is measured from the baseline box, so this is the
    // offset that pulls the glyph's ink to y = 0.
    function inkTop(m) {
        return m.tightBoundingRect.y - m.boundingRect.y;
    }

    implicitWidth: Math.max(hours.implicitWidth, minutes.implicitWidth)
    implicitHeight: hm.tightBoundingRect.height + mm.tightBoundingRect.height + lead

    StyledText {
        id: hours

        anchors.right: parent.right
        y: -root.inkTop(hm)
        text: Qt.formatDateTime(clock.date, "HH")
        color: Theme.accent
        font.pixelSize: root.px
        font.weight: Font.Bold

        TextMetrics {
            id: hm

            text: hours.text
            font: hours.font
        }
    }
    StyledText {
        id: minutes

        anchors.right: parent.right
        y: hm.tightBoundingRect.height + root.lead - root.inkTop(mm)
        text: Qt.formatDateTime(clock.date, "mm")
        color: Theme.base0E
        font.pixelSize: root.px
        font.weight: Font.Bold

        TextMetrics {
            id: mm

            text: minutes.text
            font: minutes.font
        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}

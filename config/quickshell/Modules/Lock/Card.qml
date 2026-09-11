import QtQuick
import qs.Common

// Shared surface for the lock screen's side columns. Translucent so the blurred
// wallpaper still reads through it.
StyledRect {
    id: root

    default property alias content: inner.data
    property real padding: 16

    radius: Theme.radius
    color: Qt.rgba(Theme.card.r, Theme.card.g, Theme.card.b, 0.72)
    border.width: 1
    border.color: Qt.rgba(Theme.base02.r, Theme.base02.g, Theme.base02.b, 0.55)

    Item {
        id: inner

        anchors.fill: parent
        anchors.margins: root.padding
    }
}

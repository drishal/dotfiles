import QtQuick
import qs.Common
import qs.Modules

// Wi-Fi picker straight from the bar — the network item used to launch
// nm-connection-editor, which is a whole GUI for something that belongs here.
Item {
    id: root

    // Scanning only runs while the popout is the visible one.
    property bool live: false

    implicitWidth: 340
    implicitHeight: 320
    width: implicitWidth
    height: implicitHeight

    WifiDetail {
        anchors.fill: parent
        live: root.live
        color: "transparent"
        border.width: 0
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

// Host identity. Read straight from /proc and /etc rather than shelling out —
// the lock screen should not be spawning processes to render itself.
Card {
    id: root

    property string host: ""
    property string kernel: ""

    readonly property var rows: [
        {
            i: "󰟀",
            v: root.host
        },
        {
            i: "󰌽",
            v: root.kernel
        },
        {
            i: "󰅐",
            v: "up " + Sys.formatUptime()
        }
    ]

    implicitHeight: col.implicitHeight + padding * 2

    Column {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Repeater {
            model: root.rows

            delegate: Row {
                required property var modelData

                width: col.width
                spacing: 10
                visible: modelData.v !== ""

                StyledIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.modelData.i
                    color: Theme.accent
                    font.pixelSize: 15
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 25
                    text: parent.modelData.v
                    color: Theme.base06
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }
    }

    FileView {
        path: "/etc/hostname"
        onLoaded: root.host = text().trim()
    }
    FileView {
        path: "/proc/sys/kernel/osrelease"
        onLoaded: root.kernel = text().trim()
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.UPower
import qs.Common

Item {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool charging: dev && dev.state === UPowerDeviceState.Charging
    readonly property real pct: dev ? dev.percentage : 0

    function duration(sec) {
        if (!sec || sec <= 0)
            return "—";
        const h = Math.floor(sec / 3600);
        const m = Math.floor((sec % 3600) / 60);
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }

    implicitWidth: 260
    implicitHeight: col.implicitHeight + 24
    width: implicitWidth
    height: implicitHeight

    Column {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        Row {
            spacing: 10

            StyledIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.charging ? "󰂅" : "󰁹"
                color: root.pct < 0.15 && !root.charging ? Theme.base08 : Theme.base0B
                font.pixelSize: 26
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                StyledText {
                    text: Math.round(root.pct * 100) + "%"
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }
                StyledText {
                    text: root.charging ? "Charging" : (root.dev && root.dev.state === UPowerDeviceState.FullyCharged ? "Full" : "On battery")
                    color: Theme.inkDim
                    font.pixelSize: 11
                }
            }
        }

        StyledRect {
            width: parent.width
            height: 6
            radius: 999
            color: Theme.base02

            StyledRect {
                width: parent.width * root.pct
                height: parent.height
                radius: 999
                color: root.pct < 0.15 && !root.charging ? Theme.base08 : Theme.base0B

                Behavior on width {
                    Anim {
                        type: Anim.Emphasized
                    }
                }
            }
        }

        Repeater {
            model: [
                {
                    k: root.charging ? "Time to full" : "Time remaining",
                    v: root.duration(root.charging ? (root.dev ? root.dev.timeToFull : 0) : (root.dev ? root.dev.timeToEmpty : 0))
                },
                {
                    k: "Draw",
                    v: root.dev && root.dev.changeRate ? root.dev.changeRate.toFixed(1) + " W" : "—"
                },
                {
                    k: "Health",
                    v: root.dev && root.dev.healthPercentage ? Math.round(root.dev.healthPercentage) + "%" : "—"
                }
            ]

            delegate: Item {
                required property var modelData

                width: col.width
                height: 15

                StyledText {
                    anchors.left: parent.left
                    text: modelData.k
                    color: Theme.inkDim
                    font.pixelSize: 11
                }
                StyledText {
                    anchors.right: parent.right
                    text: modelData.v
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}

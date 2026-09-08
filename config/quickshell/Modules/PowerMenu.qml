import QtQuick
import Quickshell
import qs.Common
import qs.Services

Panel {
    id: win

    readonly property var actions: [
        {
            icon: "󰍁",
            label: "Lock",
            cmd: "loginctl lock-session"
        },
        {
            icon: "󰒲",
            label: "Suspend",
            cmd: "systemctl suspend"
        },
        {
            icon: "󰍃",
            label: "Logout",
            cmd: "hyprctl dispatch 'hl.dsp.exit()'"
        },
        {
            icon: "󰜉",
            label: "Reboot",
            cmd: "systemctl reboot"
        },
        {
            icon: "󰐥",
            label: "Shutdown",
            cmd: "systemctl poweroff"
        }
    ]

    name: "powermenu"
    keyboard: true
    slideFrom: Qt.TopEdge

    width: rowFlow.implicitWidth + 32
    height: rowFlow.implicitHeight + 32

    Elevation {
        anchors.fill: menu
        radius: menu.radius
        level: 4
    }

    StyledRect {
        id: menu

        anchors.fill: parent
        radius: 18
        color: Theme.base00
        border.width: 1
        border.color: Theme.base02

        Row {
            id: rowFlow

            anchors.centerIn: parent
            spacing: 12

            Repeater {
                model: win.actions

                delegate: StyledRect {
                    id: pmBtn

                    required property var modelData

                    width: 92
                    height: 96
                    radius: 14
                    color: pmState.containsMouse ? Theme.accent : Theme.card

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        StyledIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: pmBtn.modelData.icon
                            font.pixelSize: 26
                            color: pmState.containsMouse ? Theme.accentInk : Theme.accent
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: pmBtn.modelData.label
                            font.pixelSize: 12
                            color: pmState.containsMouse ? Theme.accentInk : Theme.ink
                        }
                    }
                    StateLayer {
                        id: pmState

                        color: Theme.accentInk
                        onClicked: {
                            win.close();
                            Quickshell.execDetached(["bash", "-c", pmBtn.modelData.cmd]);
                        }
                    }
                }
            }
        }
    }
}

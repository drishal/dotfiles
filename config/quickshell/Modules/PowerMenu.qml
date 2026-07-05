import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property string screenName: screen ? screen.name : ""

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

    visible: Popups.isOpen("powermenu", win.screenName)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0
    anchors.top: true
    implicitWidth: menu.width
    implicitHeight: menu.height + 12

    Rectangle {
        id: menu
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 8
        width: rowFlow.implicitWidth + 32
        height: rowFlow.implicitHeight + 32
        radius: 18
        color: Theme.base00
        border.width: 1
        border.color: Theme.base02
        focus: win.visible
        Keys.onEscapePressed: Popups.close("powermenu", win.screenName)

        Row {
            id: rowFlow
            anchors.centerIn: parent
            spacing: 12

            Repeater {
                model: win.actions
                delegate: Rectangle {
                    id: pmBtn
                    required property var modelData
                    width: 92
                    height: 96
                    radius: 14
                    color: pmMa.containsMouse ? Theme.accent : Theme.card
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: pmBtn.modelData.icon
                            font.family: Theme.fontMono
                            font.pixelSize: 26
                            color: pmMa.containsMouse ? Theme.accentInk : Theme.accent
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: pmBtn.modelData.label
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: pmMa.containsMouse ? Theme.accentInk : Theme.ink
                        }
                    }
                    MouseArea {
                        id: pmMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Popups.close("powermenu", win.screenName);
                            Quickshell.execDetached(["bash", "-c", pmBtn.modelData.cmd]);
                        }
                    }
                }
            }
        }
    }
}

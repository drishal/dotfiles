import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs.Common
import qs.Services

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    readonly property string screenName: bar.screen ? bar.screen.name : ""
    readonly property string launchCmd: "rofi -show drun -icon-theme Papirus -show-icons"

    WlrLayershell.namespace: "quickshell-bar"
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 36
    exclusiveZone: 36

    // ── reusable glyph button ──────────────────────────────────────────────
    component IconButton: Item {
        id: ib
        property string glyph
        property color fg: Theme.inkDim
        property color hoverFg: Theme.accent
        property int glyphSize: 14
        property real padH: 8
        signal clicked
        implicitWidth: t.implicitWidth + padH * 2
        implicitHeight: 24
        Rectangle {
            anchors.fill: parent
            radius: 8
            color: ma.containsMouse ? Theme.base01 : "transparent"
        }
        Text {
            id: t
            anchors.centerIn: parent
            text: ib.glyph
            color: ma.containsMouse ? ib.hoverFg : ib.fg
            font.family: Theme.fontMono
            font.pixelSize: ib.glyphSize
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ib.clicked()
        }
    }

    component Sep: Text {
        text: "|"
        color: Theme.base03
        font.pixelSize: 18
        leftPadding: 5
        rightPadding: 5
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    }

    // ── the floating island ────────────────────────────────────────────────
    Rectangle {
        id: island
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 6
        anchors.bottomMargin: 0
        radius: 16
        color: Theme.island
        border.width: 1
        border.color: Theme.base02

        // ── LEFT: launcher · workspaces · focused window ──────────────────
        Row {
            id: leftRow
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            IconButton {
                glyph: "󰀻"
                fg: Theme.base0D
                hoverFg: Theme.base0C
                glyphSize: 16
                anchors.verticalCenter: parent.verticalCenter
                onClicked: Quickshell.execDetached(["bash", "-c", bar.launchCmd])
            }

            Workspaces {
                screenName: bar.screenName
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 10
                text: ToplevelManager.activeToplevel ? (ToplevelManager.activeToplevel.title || "") : ""
                color: Theme.inkDim
                font.family: Theme.fontSans
                font.pixelSize: 13
                elide: Text.ElideRight
                maximumLineCount: 1
                width: Math.min(implicitWidth, 360)
            }
        }

        // ── CENTER: clock → notification center, with unread dot ───────────
        Item {
            anchors.centerIn: parent
            implicitWidth: clockRow.implicitWidth + 20
            height: 24
            Rectangle {
                anchors.fill: parent
                radius: 10
                color: clockMa.containsMouse ? Theme.base01 : "transparent"
            }
            Row {
                id: clockRow
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "MMM d   HH:mm")
                    color: Theme.ink
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Notif.count > 0
                    width: 7
                    height: 7
                    radius: 4
                    color: Theme.base0A
                }
            }
            MouseArea {
                id: clockMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Popups.toggle("notes", bar.screenName)
            }
            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }
        }

        // ── RIGHT: battery · net · mem · cpu · tray · settings · power ─────
        Row {
            id: rightRow
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9

            // battery (only if a laptop battery is present)
            Row {
                readonly property var dev: UPower.displayDevice
                readonly property bool present: dev && dev.isLaptopBattery && dev.ready
                readonly property bool charging: present && dev.state === UPowerDeviceState.Charging
                visible: present
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.charging ? "󰂅" : "󰁹"
                    color: Theme.base0B
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.present ? Math.round(parent.dev.percentage * 100) + "%" : ""
                    color: Theme.base0B
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                }
            }

            // network
            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: netRow.implicitWidth + 16
                implicitHeight: 22
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: netMa.containsMouse ? Theme.base01 : "transparent"
                }
                Row {
                    id: netRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Net.icon
                        color: Theme.base0D
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Net.label
                        color: Theme.inkDim
                        font.family: Theme.fontSans
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        width: Math.min(implicitWidth, 130)
                    }
                }
                MouseArea {
                    id: netMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["nm-connection-editor"])
                }
            }

            Sep {
                anchors.verticalCenter: parent.verticalCenter
            }

            // mem
            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: Theme.base09
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Sys.memUsedGb.toFixed(1) + "G"
                    color: Sys.memPercent >= 90 ? Theme.base08 : Theme.base09
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                }
            }
            // cpu
            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: Theme.base0C
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Sys.cpu + "%"
                    color: Sys.cpu >= 85 ? Theme.base08 : Theme.base0C
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                }
            }

            Sep {
                anchors.verticalCenter: parent.verticalCenter
            }

            IconButton {
                glyph: "󰅍"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: Popups.toggle("clipboard", bar.screenName)
            }

            Sep {
                anchors.verticalCenter: parent.verticalCenter
            }

            // system tray
            Row {
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter
                visible: SystemTray.items && SystemTray.items.values.length > 0
                Repeater {
                    model: SystemTray.items ? SystemTray.items.values : []
                    delegate: Item {
                        id: trayItem
                        required property var modelData
                        width: 22
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: trayItem.modelData.icon
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 16
                            sourceSize.height: 16
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu)
                                    trayMenu.open();
                                else
                                    trayItem.modelData.activate();
                            }
                        }
                        QsMenuAnchor {
                            id: trayMenu
                            menu: trayItem.modelData.menu
                            anchor.window: bar
                            anchor.rect.x: trayItem.x + leftRow.x
                            anchor.rect.y: island.height
                        }
                    }
                }
            }

            Sep {
                anchors.verticalCenter: parent.verticalCenter
                visible: SystemTray.items && SystemTray.items.values.length > 0
            }

            IconButton {
                glyph: "󰘮"
                glyphSize: 15
                anchors.verticalCenter: parent.verticalCenter
                onClicked: Popups.toggle("dashboard", bar.screenName)
            }
            IconButton {
                glyph: "󰐥"
                glyphSize: 15
                hoverFg: Theme.base08
                anchors.verticalCenter: parent.verticalCenter
                onClicked: Popups.toggle("powermenu", bar.screenName)
            }
        }
    }
}

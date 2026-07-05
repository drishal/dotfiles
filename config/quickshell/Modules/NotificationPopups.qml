import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.Common
import qs.Services

// Transient notification popups, top-right (mirrors ags NotificationPopups).
// Sourced from Notif.popups (auto-hidden after 5s; critical never auto-hides).

PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notification-popups"
    exclusiveZone: 0
    anchors.top: true
    implicitWidth: 420
    implicitHeight: Math.max(1, col.implicitHeight + 16)
    visible: Notif.popups.length > 0

    // Anchored top-only → the layer surface is horizontally centered, so the
    // popups drop straight under the centered clock (matches the ags TOP anchor).
    Column {
        id: col
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 8
        spacing: 8

        Repeater {
            model: Notif.popups
            delegate: Rectangle {
                id: pcard
                required property var modelData
                readonly property var n: modelData.n
                readonly property bool critical: n.urgency === NotificationUrgency.Critical
                readonly property var acts: Notif.visibleActions(n)
                width: 400
                radius: 16
                color: Theme.base00
                border.width: 1
                border.color: critical ? Theme.base08 : Theme.base02
                implicitHeight: content.implicitHeight + 24

                Column {
                    id: content
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 4

                    // header
                    Row {
                        width: parent.width
                        spacing: 8
                        Text {
                            width: parent.width - closeBtn.width - timeTxt.width - 16
                            text: pcard.n.appName || "Notification"
                            color: Theme.inkDim
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: timeTxt
                            text: Qt.formatDateTime(new Date(pcard.modelData.time), "HH:mm")
                            color: Theme.inkDim
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: closeBtn
                            text: "󰅖"
                            color: closeMa.containsMouse ? Theme.base08 : Theme.inkDim
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                            MouseArea {
                                id: closeMa
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notif.dismiss(pcard.n)
                            }
                        }
                    }

                    // content
                    Row {
                        width: parent.width
                        spacing: 12
                        Image {
                            visible: source != ""
                            source: pcard.n.image || ""
                            width: visible ? 48 : 0
                            height: 48
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 48
                            sourceSize.height: 48
                        }
                        Column {
                            width: parent.width - (pcard.n.image ? 60 : 0)
                            spacing: 2
                            Text {
                                width: parent.width
                                text: pcard.n.summary || ""
                                color: Theme.ink
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                visible: (pcard.n.body || "") !== ""
                                text: pcard.n.body || ""
                                color: Theme.inkDim
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                                textFormat: Text.MarkdownText
                                wrapMode: Text.WordWrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // actions
                    Row {
                        width: parent.width
                        spacing: 6
                        visible: pcard.acts.length > 0
                        Repeater {
                            model: pcard.acts
                            delegate: Rectangle {
                                id: actBtn
                                required property var modelData
                                width: (content.width - (pcard.acts.length - 1) * 6) / Math.max(1, pcard.acts.length)
                                height: 32
                                radius: 10
                                color: actMa.containsMouse ? Theme.accent : Theme.base02
                                Text {
                                    anchors.centerIn: parent
                                    text: actBtn.modelData.text
                                    color: actMa.containsMouse ? Theme.accentInk : Theme.ink
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    id: actMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: actBtn.modelData.invoke()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

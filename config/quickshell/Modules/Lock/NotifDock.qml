pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.Common
import qs.Services

// Notifications while locked. FadeListView + ScriptModel rather than a Repeater:
// Notif.list is unbounded-ish (capped at maxList) and a Repeater would rebuild
// every delegate on each arrival.
//
// Everything here renders as PlainText — StyledText's default. The notification
// centre opts bodies into Markdown, but this surface is showing untrusted text
// to someone who has not authenticated yet.
Card {
    id: root

    padding: 12

    Item {
        anchors.fill: parent

        Row {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 22
            spacing: 8

            StyledIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: Notif.count > 0 ? "󰂚" : "󰂛"
                color: Notif.count > 0 ? Theme.accent : Theme.base03
                font.pixelSize: 15
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                color: Theme.base06
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            StyledRect {
                anchors.verticalCenter: parent.verticalCenter
                visible: Notif.count > 0
                width: countText.implicitWidth + 12
                height: 18
                radius: 999
                color: Theme.accent

                StyledText {
                    id: countText

                    anchors.centerIn: parent
                    text: "" + Notif.count
                    color: Theme.accentInk
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: Notif.count === 0
            text: "You're all caught up"
            color: Theme.base03
            font.pixelSize: 12
        }

        FadeListView {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: 10
            visible: Notif.count > 0
            clip: true
            spacing: 8

            model: ScriptModel {
                values: Notif.list
            }

            delegate: StyledRect {
                id: card

                required property var modelData

                readonly property var n: modelData.n

                width: ListView.view.width
                height: body.implicitHeight + 20
                radius: Theme.radiusSm
                color: Theme.base02

                Row {
                    id: body

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 10
                    spacing: 10

                    StyledRect {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        radius: width / 2
                        color: card.n && card.n.image ? "transparent" : Theme.base01
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: card.n && card.n.image ? card.n.image : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            // Screenshot notifications arrive at full resolution;
                            // decoding one at 1920x1080 for a 32px avatar is how
                            // the shell used to bloat.
                            sourceSize.width: 64
                            sourceSize.height: 64
                            visible: status === Image.Ready
                        }
                        StyledIcon {
                            anchors.centerIn: parent
                            visible: !(card.n && card.n.image)
                            text: "󰎟"
                            color: Theme.inkDim
                            font.pixelSize: 15
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 42 - dismiss.width - parent.spacing * 2
                        spacing: 2

                        StyledText {
                            width: parent.width
                            text: card.n ? (card.n.summary || card.n.appName || "Notification") : ""
                            color: Theme.base07
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        StyledText {
                            width: parent.width
                            visible: text !== ""
                            text: card.n ? (card.n.body || "") : ""
                            color: Theme.inkDim
                            font.pixelSize: 11
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                        }
                    }

                    StyledIcon {
                        id: dismiss

                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅖"
                        color: dismissMouse.containsMouse ? Theme.base08 : Theme.base03
                        font.pixelSize: 14

                        MouseArea {
                            id: dismissMouse

                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notif.dismiss(card.n)
                        }
                    }
                }
            }
        }
    }
}

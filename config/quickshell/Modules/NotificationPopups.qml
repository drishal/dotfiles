import QtQuick
import Quickshell.Services.Notifications
import qs.Common
import qs.Services

// Transient notification popups, top-centre. Sourced from Notif.popups
// (auto-hidden after 5s; critical never auto-hides). Cards spring in, and drag
// sideways to dismiss.

Item {
    id: win

    required property string screenName

    width: 420
    height: Math.max(1, col.implicitHeight + 16)
    visible: Notif.popups.length > 0

    Column {
        id: col

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 8
        spacing: 8

        Repeater {
            model: Notif.popups

            delegate: Item {
                id: slot

                required property var modelData

                readonly property var n: modelData.n
                readonly property bool critical: n.urgency === NotificationUrgency.Critical
                readonly property var acts: Notif.visibleActions(n)
                readonly property real dismissAt: 130

                width: 400
                height: pcard.height

                // Spring in on arrival.
                scale: 0
                opacity: 0
                Component.onCompleted: {
                    scale = 1;
                    opacity = 1;
                }

                Behavior on scale {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }
                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                Elevation {
                    anchors.fill: pcard
                    radius: pcard.radius
                    level: 3
                }

                StyledRect {
                    id: pcard

                    x: drag.dx
                    width: parent.width
                    radius: 16
                    color: Theme.base00
                    border.width: 1
                    border.color: slot.critical ? Theme.base08 : Theme.base02
                    implicitHeight: content.implicitHeight + 24
                    height: implicitHeight
                    // Fade as it is pulled aside, so the gesture reads as a throw.
                    opacity: 1 - Math.min(0.75, Math.abs(drag.dx) / (slot.dismissAt * 2))

                    Behavior on x {
                        enabled: !drag.dragging

                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    MouseArea {
                        id: drag

                        property real dx: 0
                        property real pressX: 0
                        property bool dragging: false

                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.ArrowCursor

                        onPressed: event => {
                            pressX = event.x;
                            dragging = true;
                        }
                        onPositionChanged: event => {
                            if (dragging)
                                dx = event.x - pressX;
                        }
                        onReleased: {
                            dragging = false;
                            if (Math.abs(dx) > slot.dismissAt) {
                                dx = dx > 0 ? 600 : -600;
                                slot.opacity = 0;
                                Notif.dismiss(slot.n);
                            } else {
                                dx = 0;
                            }
                        }
                        onCanceled: {
                            dragging = false;
                            dx = 0;
                        }
                        onClicked: event => {
                            if (event.button === Qt.MiddleButton)
                                Notif.dismiss(slot.n);
                        }
                    }

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

                            StyledText {
                                width: parent.width - closeBtn.width - timeTxt.width - 16
                                text: slot.n.appName || "Notification"
                                color: Theme.inkDim
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText {
                                id: timeTxt

                                text: Qt.formatDateTime(new Date(slot.modelData.time), "HH:mm")
                                color: Theme.inkDim
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledIcon {
                                id: closeBtn

                                text: "󰅖"
                                color: closeState.containsMouse ? Theme.base08 : Theme.inkDim
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter

                                StateLayer {
                                    id: closeState

                                    anchors.margins: -4
                                    radius: 999
                                    color: Theme.base08
                                    onClicked: Notif.dismiss(slot.n)
                                }
                            }
                        }

                        // content
                        Row {
                            width: parent.width
                            spacing: 12

                            Image {
                                visible: source != ""
                                source: slot.n.image || ""
                                width: visible ? 48 : 0
                                height: 48
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 48
                                sourceSize.height: 48
                            }
                            Column {
                                width: parent.width - (slot.n.image ? 60 : 0)
                                spacing: 2

                                StyledText {
                                    width: parent.width
                                    text: slot.n.summary || ""
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                StyledText {
                                    width: parent.width
                                    visible: (slot.n.body || "") !== ""
                                    text: slot.n.body || ""
                                    color: Theme.inkDim
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
                            visible: slot.acts.length > 0

                            Repeater {
                                model: slot.acts

                                delegate: StyledRect {
                                    id: actBtn

                                    required property var modelData

                                    width: (content.width - (slot.acts.length - 1) * 6) / Math.max(1, slot.acts.length)
                                    height: 32
                                    radius: 10
                                    color: actState.containsMouse ? Theme.accent : Theme.base02

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: actBtn.modelData.text
                                        color: actState.containsMouse ? Theme.accentInk : Theme.ink
                                        font.pixelSize: 12
                                    }
                                    StateLayer {
                                        id: actState

                                        color: Theme.accentInk
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
}

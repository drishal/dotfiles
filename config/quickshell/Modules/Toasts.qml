pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Services

// Internal toast stack UI, bottom-right on the Overlay layer (beside the
// volume OSD at bottom-centre). Cards spring in from the right edge and fade
// out before removal. Sourced from Toaster.list — plain objects with a
// `closed`-style dismissal handled by the service.

Item {
    id: win

    required property string screenName

    width: 360
    height: Math.max(1, col.implicitHeight)
    visible: Toaster.list.length > 0

    Column {
        id: col

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        spacing: 8

        // Newest first matches the service's list order (index 0 = newest).
        Repeater {
            model: Toaster.list

            delegate: Item {
                id: slot

                required property var modelData
                required property int index

                readonly property bool error: modelData.type === Toaster.Error
                readonly property bool warning: modelData.type === Toaster.Warning
                readonly property color edge: slot.error ? Theme.base08 : slot.warning ? Theme.base09 : Theme.accent

                width: 344
                height: tcard.height + 8

                // Spring in on arrival.
                opacity: 0
                Component.onCompleted: slot.opacity = 1
                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                StyledRect {
                    id: tcard

                    anchors.right: parent.right
                    width: parent.width
                    radius: 14
                    color: Theme.base00
                    border.width: 1
                    border.color: Theme.base02
                    height: tcontent.implicitHeight + 22

                    // Severity edge, left.
                    StyledRect {
                        anchors.left: parent.left
                        anchors.leftMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        radius: 2
                        height: parent.height - 16
                        color: slot.edge
                    }

                    Row {
                        id: tcontent

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        anchors.leftMargin: 16
                        spacing: 10

                        StyledIcon {
                            anchors.top: parent.top
                            text: slot.modelData.icon || (slot.error ? "󰅚" : slot.warning ? "󰀪" : "󰋗")
                            font.pixelSize: 18
                            color: slot.edge
                        }
                        Column {
                            width: parent.width - 30 - closeBtn.width - 8
                            spacing: 2

                            StyledText {
                                width: parent.width
                                text: slot.modelData.summary
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            StyledText {
                                width: parent.width
                                visible: (slot.modelData.body || "") !== ""
                                text: slot.modelData.body
                                color: Theme.inkDim
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }
                        StyledIcon {
                            id: closeBtn

                            anchors.top: parent.top
                            text: "󰅖"
                            color: closeMa.containsMouse ? Theme.base08 : Theme.inkDim
                            font.pixelSize: 12

                            MouseArea {
                                id: closeMa

                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Toaster.close(slot.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}

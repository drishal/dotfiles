pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Services

// Dots plus a blinking caret rather than a real TextInput: the surface never
// holds the password in an input item, only in LockState's buffer.
StyledRect {
    id: root

    readonly property bool busy: LockState.status === LockState.Authenticating
    readonly property bool failed: LockState.status === LockState.Failed || LockState.status === LockState.MaxTries

    // Past this the dots would outgrow the pill; the count keeps scrolling.
    readonly property int maxDots: 18

    implicitWidth: 340
    implicitHeight: 50
    radius: height / 2
    color: Qt.rgba(Theme.base00.r, Theme.base00.g, Theme.base00.b, 0.78)
    border.width: 2
    border.color: root.failed ? Theme.base08 : root.busy ? Theme.base0A : Theme.accent

    Row {
        anchors.centerIn: parent
        spacing: 10

        StyledIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.busy ? "󰔟" : "󰌾"
            color: root.failed ? Theme.base08 : Theme.inkDim
            font.pixelSize: 17
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            visible: LockState.buffer.length > 0

            Repeater {
                model: Math.min(root.maxDots, LockState.buffer.length)

                delegate: StyledRect {
                    width: 9
                    height: 9
                    radius: width / 2
                    color: Theme.ink

                    scale: 0
                    Component.onCompleted: scale = 1

                    Behavior on scale {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                }
            }
        }

        // Blinks only while idle — a caret that keeps blinking under a spinner
        // reads as though input is still being taken.
        StyledRect {
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 20
            radius: 1
            color: Theme.accent
            visible: !root.busy

            SequentialAnimation on opacity {
                running: !root.busy
                loops: Animation.Infinite

                PropertyAction {
                    value: 1
                }
                PauseAnimation {
                    duration: 520
                }
                PropertyAction {
                    value: 0
                }
                PauseAnimation {
                    duration: 420
                }
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: LockState.buffer.length === 0
            text: root.busy ? "Checking…" : "Enter password"
            color: Theme.inkDim
            font.pixelSize: 13
        }
    }

    StyledText {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        visible: LockState.buffer.length > root.maxDots
        text: "+" + (LockState.buffer.length - root.maxDots)
        color: Theme.inkDim
        font.pixelSize: 11
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.Common
import qs.Services

// The auth column: clock, date, avatar, password, PAM message.
Item {
    id: root

    // Shrinks the hero type on short displays so the column still fits.
    readonly property real sizeScale: Math.min(1, height / 1200)

    property real shakeX: 0

    implicitWidth: 380

    transform: Translate {
        x: root.shakeX
    }

    Connections {
        target: LockState

        function onShake() {
            shakeAnim.restart();
        }
    }

    SequentialAnimation {
        id: shakeAnim

        loops: 2

        Anim {
            target: root
            property: "shakeX"
            to: -14
            type: Anim.FastEffects
            duration: 60
        }
        Anim {
            target: root
            property: "shakeX"
            to: 14
            type: Anim.FastEffects
            duration: 60
        }
        Anim {
            target: root
            property: "shakeX"
            to: 0
            type: Anim.FastEffects
            duration: 60
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: Math.round(26 * root.sizeScale)

        Clock {
            anchors.horizontalCenter: parent.horizontalCenter
            sizeScale: root.sizeScale
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(dateClock.date, "dddd • d MMMM").toUpperCase()
            color: Theme.base06
            font.pixelSize: Math.round(15 * root.sizeScale)
            font.weight: Font.DemiBold
            font.letterSpacing: 2.5
        }

        ProfilePic {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: Math.round(132 * root.sizeScale)
            implicitHeight: Math.round(132 * root.sizeScale)
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Quickshell.env("USER") || "user"
            color: Theme.base07
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }

        PasswordField {
            anchors.horizontalCenter: parent.horizontalCenter
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: LockState.message
            color: LockState.status === LockState.Idle ? Theme.inkDim : Theme.base08
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            opacity: text === "" ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    SystemClock {
        id: dateClock

        precision: SystemClock.Minutes
    }
}

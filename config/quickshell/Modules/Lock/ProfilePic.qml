pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.Common
import qs.Services

// Avatar ringed by PAM state: accent idle, amber while authenticating, red on
// failure. Progress is an orbiting dot rather than a gap in the ring — a gap
// would have to be painted in the background colour, and the background here is
// a blurred wallpaper.
Item {
    id: root

    readonly property bool busy: LockState.status === LockState.Authenticating
    readonly property bool failed: LockState.status === LockState.Failed || LockState.status === LockState.MaxTries
    readonly property color stateColor: failed ? Theme.base08 : busy ? Theme.base0A : Theme.accent

    implicitWidth: 132
    implicitHeight: 132

    StyledRect {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 3
        border.color: root.busy ? Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.35) : root.stateColor
    }

    Item {
        anchors.fill: parent
        visible: root.busy

        StyledRect {
            anchors.horizontalCenter: parent.horizontalCenter
            y: -4
            width: 11
            height: 11
            radius: width / 2
            color: root.stateColor
        }

        RotationAnimator on rotation {
            running: root.busy
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 1100
        }
    }

    StyledRect {
        anchors.fill: parent
        anchors.margins: 9
        radius: width / 2
        color: Theme.base02
        clip: true

        Image {
            id: face

            anchors.fill: parent
            source: Quickshell.env("HOME") + "/.face"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 264
            sourceSize.height: 264
            visible: status === Image.Ready
        }
        StyledIcon {
            anchors.centerIn: parent
            visible: !face.visible
            text: "󰀄"
            font.pixelSize: 48
            color: Theme.inkDim
        }
    }
}

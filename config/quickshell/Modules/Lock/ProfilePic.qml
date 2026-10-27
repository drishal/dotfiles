pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Common
import qs.Services

// Avatar in an M3 cookie, ringed by PAM state: accent idle, amber while
// authenticating, red on failure. While PAM works the ring spins and swells
// into a burst; the photo is masked to the same cookie so the two stay
// concentric.
Item {
    id: root

    readonly property bool busy: LockState.status === LockState.Authenticating
    readonly property bool failed: LockState.status === LockState.Failed || LockState.status === LockState.MaxTries
    readonly property color stateColor: failed ? Theme.base08 : busy ? Theme.base0A : Theme.accent

    implicitWidth: 132
    implicitHeight: 132

    PolarShape {
        id: ring

        anchors.fill: parent
        lobes: 12
        amplitude: 0.035
        lobes2: 8
        amplitude2: 0.07
        morph: root.busy ? 1 : 0
        fillColor: "transparent"
        strokeColor: root.stateColor
        strokeWidth: 3

        Behavior on morph {
            Anim {
                type: Anim.DefaultSpatial
            }
        }
        Behavior on strokeColor {
            CAnim {}
        }
        RotationAnimator on rotation {
            running: root.busy
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 1800
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 9

        PolarShape {
            id: mask

            anchors.fill: parent
            lobes: 12
            amplitude: 0.035
            fillColor: "white"
            visible: false
            layer.enabled: true
        }

        PolarShape {
            anchors.fill: parent
            lobes: 12
            amplitude: 0.035
            fillColor: Theme.base02
        }

        Image {
            id: face

            anchors.fill: parent
            source: Quickshell.env("HOME") + "/.face"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 264
            sourceSize.height: 264
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: face
            visible: face.status === Image.Ready
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
        StyledIcon {
            anchors.centerIn: parent
            visible: face.status !== Image.Ready
            text: "󰀄"
            font.pixelSize: 48
            color: Theme.inkDim
        }
    }
}

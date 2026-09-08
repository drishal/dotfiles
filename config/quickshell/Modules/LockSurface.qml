import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import qs.Common
import qs.Services

// Visuals for the session lock. Split out from LockScreen so it can be
// instantiated (and so type-checked) without actually locking the session.

Item {
    id: surface

    // The lock surface this fills; used only to tell which monitor is focused.
    property var screen: null

    readonly property string screenName: screen ? screen.name : ""
    readonly property bool primary: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === screenName
    readonly property bool busy: LockState.status === LockState.Authenticating

    // ── blurred wallpaper ──
    Image {
        id: wall

        anchors.fill: parent
        source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
        sourceSize.width: surface.width
        sourceSize.height: surface.height
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        blurEnabled: true
        blur: 1
        blurMax: 48
        saturation: -0.2
    }
    // Sits under the wallpaper when it fails to load, over it otherwise.
    Rectangle {
        anchors.fill: parent
        color: Theme.base00
        opacity: wall.status === Image.Ready ? 0.55 : 1
    }

    // ── clock ──
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.16
        spacing: -6

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(lockClock.date, "HH:mm")
            color: Theme.base07
            font.pixelSize: 128
            font.weight: Font.Bold
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(lockClock.date, "dddd, d MMMM")
            color: Theme.base06
            font.pixelSize: 20
        }
    }

    // ── auth card ──
    Item {
        id: authCard

        property real shakeX: 0

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: parent.height * 0.14
        width: 360
        height: 220
        x: shakeX

        transform: Translate {
            x: authCard.shakeX
        }

        SequentialAnimation {
            id: shakeAnim

            loops: 2

            Anim {
                target: authCard
                property: "shakeX"
                to: -14
                type: Anim.FastEffects
                duration: 60
            }
            Anim {
                target: authCard
                property: "shakeX"
                to: 14
                type: Anim.FastEffects
                duration: 60
            }
            Anim {
                target: authCard
                property: "shakeX"
                to: 0
                type: Anim.FastEffects
                duration: 60
            }
        }

        Connections {
            target: LockState

            function onShake() {
                shakeAnim.restart();
            }
        }

        Column {
            anchors.fill: parent
            spacing: 16

            // avatar with a ring that spins while PAM is working
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 108
                height: 108

                Rectangle {
                    id: ring

                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 3
                    border.color: {
                        if (LockState.status === LockState.Failed || LockState.status === LockState.MaxTries)
                            return Theme.base08;
                        if (surface.busy)
                            return Theme.base0A;
                        return Theme.accent;
                    }

                    Behavior on border.color {
                        CAnim {}
                    }

                    // A gap in the ring makes the spin legible.
                    Rectangle {
                        width: 18
                        height: 5
                        color: "transparent"
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -2
                    }

                    RotationAnimator on rotation {
                        running: surface.busy
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1400
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 8
                    radius: width / 2
                    color: Theme.base02
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: Quickshell.env("HOME") + "/.face"
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 200
                        sourceSize.height: 200
                        visible: status === Image.Ready
                    }
                    StyledIcon {
                        anchors.centerIn: parent
                        text: "󰀄"
                        font.pixelSize: 40
                        color: Theme.inkDim
                    }
                }
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Quickshell.env("USER") || "user"
                color: Theme.base07
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            // password pill — dots rather than a text field, so the
            // surface never needs a real input item to be secure
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300
                height: 46
                radius: 999
                color: Qt.rgba(Theme.base00.r, Theme.base00.g, Theme.base00.b, 0.8)
                border.width: 1
                border.color: surface.primary ? Theme.accent : Theme.base02

                Behavior on border.color {
                    CAnim {}
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    StyledIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: surface.busy ? "󰔟" : "󰌾"
                        color: Theme.inkDim
                        font.pixelSize: 16
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        visible: LockState.buffer.length > 0

                        Repeater {
                            model: Math.min(16, LockState.buffer.length)

                            delegate: Rectangle {
                                width: 8
                                height: 8
                                radius: 4
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
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: LockState.buffer.length === 0
                        text: surface.busy ? "Checking…" : "Enter password"
                        color: Theme.inkDim
                        font.pixelSize: 13
                    }
                }
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LockState.message
                color: LockState.status === LockState.Idle ? Theme.inkDim : Theme.base08
                font.pixelSize: 12
                opacity: text === "" ? 0 : 1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }

    // ── status strip ──
    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 28
        spacing: 18

        Row {
            spacing: 8
            visible: player !== null

            readonly property var player: {
                const ps = Mpris.players ? Mpris.players.values : [];
                return ps.length > 0 ? ps[0] : null;
            }

            StyledIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰝚"
                color: Theme.accent
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.player ? (parent.player.trackTitle || "") : ""
                color: Theme.base06
                font.pixelSize: 12
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 260)
            }
        }

        Row {
            spacing: 8

            StyledIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: Net.icon
                color: Theme.base0D
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Net.label
                color: Theme.base06
                font.pixelSize: 12
            }
        }

        Row {
            readonly property var dev: UPower.displayDevice
            readonly property bool present: dev && dev.isLaptopBattery && dev.ready

            spacing: 8
            visible: present

            StyledIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰁹"
                color: Theme.base0B
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.present ? Math.round(parent.dev.percentage * 100) + "%" : ""
                color: Theme.base06
                font.pixelSize: 12
            }
        }
    }

    SystemClock {
        id: lockClock

        precision: SystemClock.Minutes
    }

    // Keys go to whichever surface the compositor focused; the buffer is
    // shared, so it does not matter which one that is.
    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (LockState.status === LockState.Authenticating)
                return;
            if (LockState.status === LockState.MaxTries)
                return;

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                LockState.status = LockState.Authenticating;
                LockState.message = "";
                LockState.submit();
            } else if (event.key === Qt.Key_Backspace) {
                LockState.buffer = event.modifiers & Qt.ControlModifier ? "" : LockState.buffer.slice(0, -1);
            } else if (event.key === Qt.Key_Escape) {
                LockState.buffer = "";
            } else if (/^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
                LockState.buffer += event.text;
            }
            event.accepted = true;
        }
    }
}

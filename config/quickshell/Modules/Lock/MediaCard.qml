pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Mpris
import qs.Common
import qs.Services

Card {
    id: root

    // Players.active prefers whatever is playing, then mpv, then first.
    readonly property var player: Players.active
    readonly property bool playing: player && player.playbackState === MprisPlaybackState.Playing

    // Sized to its content rather than stretched to fill the column — a media
    // card with one track in it should not be a half-screen slab.
    implicitHeight: 132 + (progress.visible ? progress.implicitHeight + 8 : 0)

    component Ctl: Item {
        id: ctl

        property alias text: icon.text
        property bool active: true
        property int iconSize: 20
        property color tint: Theme.base06

        signal triggered

        implicitWidth: 36
        implicitHeight: 36

        StyledIcon {
            id: icon

            anchors.centerIn: parent
            color: ctl.active ? ctl.tint : Theme.base03
            font.pixelSize: ctl.iconSize
            opacity: mouse.containsMouse && ctl.active ? 1 : 0.85

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }
        }
        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: ctl.active ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (ctl.active)
                ctl.triggered()
        }
    }

    // Behind everything, so the card reads as one surface with the music in it.
    Visualizer {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.6
        active: root.playing
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
    }

    StyledText {
        anchors.centerIn: parent
        visible: !root.player
        text: "Nothing playing"
        color: Theme.inkDim
        font.pixelSize: 12
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.player
        spacing: 12

        Row {
            width: parent.width
            spacing: 12

            StyledRect {
                anchors.verticalCenter: parent.verticalCenter
                width: 52
                height: 52
                radius: Theme.radiusSm
                color: Theme.base02
                clip: true

                Image {
                    id: art

                    anchors.fill: parent
                    source: Players.artUrl(root.player)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 104
                    sourceSize.height: 104
                    visible: status === Image.Ready
                }
                StyledIcon {
                    anchors.centerIn: parent
                    visible: !art.visible
                    text: "󰝚"
                    color: Theme.inkDim
                    font.pixelSize: 22
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 64
                spacing: 3

                StyledText {
                    width: parent.width
                    text: root.player ? (root.player.trackTitle || "Unknown") : ""
                    color: Theme.base07
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                StyledText {
                    width: parent.width
                    text: root.player ? (root.player.trackArtist || "") : ""
                    color: Theme.inkDim
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        MediaProgress {
            id: progress

            width: parent.width
            player: root.player
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            Ctl {
                text: "󰒮"
                active: root.player && root.player.canGoPrevious
                onTriggered: root.player.previous()
            }
            Ctl {
                text: root.playing ? "󰏤" : "󰐊"
                active: root.player && root.player.canTogglePlaying
                iconSize: 26
                tint: Theme.accent
                onTriggered: root.player.togglePlaying()
            }
            Ctl {
                text: "󰒭"
                active: root.player && root.player.canGoNext
                onTriggered: root.player.next()
            }
        }
    }
}

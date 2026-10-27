pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Mpris
import qs.Common

// Wavy track position for an MPRIS player, with elapsed / total times and
// click-to-seek. MPRIS does not push position updates, so it is re-read once
// a second, and only while this is on screen and the player is playing.
Column {
    id: root

    property var player: null
    property bool showTimes: true

    readonly property bool playing: player !== null && player.playbackState === MprisPlaybackState.Playing
    readonly property bool known: player !== null && player.positionSupported && player.length > 0

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        const h = Math.floor(s / 3600);
        const m = Math.floor(s / 60) % 60;
        const sec = String(s % 60).padStart(2, "0");
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + sec : m + ":" + sec;
    }

    spacing: 2
    visible: known

    Timer {
        interval: 1000
        repeat: true
        running: root.visible && root.playing
        triggeredOnStart: true
        onTriggered: root.player.positionChanged()
    }

    WavyProgress {
        width: parent.width
        value: root.known ? root.player.position / root.player.length : 0
        playing: root.playing
        seekable: root.known && root.player.canSeek
        onSeek: fraction => root.player.position = fraction * root.player.length
    }

    Item {
        width: parent.width
        height: elapsed.implicitHeight
        visible: root.showTimes

        StyledText {
            id: elapsed

            text: root.known ? root.fmt(root.player.position) : ""
            color: Theme.inkDim
            font.pixelSize: 10
        }
        StyledText {
            anchors.right: parent.right
            text: root.known ? root.fmt(root.player.length) : ""
            color: Theme.inkDim
            font.pixelSize: 10
        }
    }
}

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Bluetooth
import Quickshell.Widgets
import qs.Common
import qs.Services

// Quick-settings control center, top-right. Tiles (network/bluetooth/airplane/
// mic/DND/volume), volume+brightness sliders, and the mpris media player.
//
// The card is free to grow and shrink now: the window behind this panel spans
// the whole screen and never resizes, so expanding a detail costs one input
// region update per frame instead of a layer-shell reconfigure. That retires
// the old reserved-height workaround entirely.

Panel {
    id: win

    name: "dashboard"
    keyboard: true
    slideFrom: Qt.TopEdge

    width: 404
    height: card.implicitHeight

    // Inline detail panel below the tiles ("" = collapsed), DMS-style.
    property string expandedSection: ""
    onShownChanged: {
        if (shown) {
            Radios.addRef();
        } else {
            Radios.removeRef();
            expandedSection = "";
        }
    }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var player: {
        const ps = Mpris.players ? Mpris.players.values : [];
        const sorted = ps.slice().sort((a, b) => {
            const am = /mpv/i.test(a.identity || "");
            const bm = /mpv/i.test(b.identity || "");
            return am === bm ? 0 : (am ? -1 : 1);
        });
        return sorted[0] || null;
    }

    // ── reusable quick-toggle tile ─────────────────────────────────────────
    component Tile: StyledRect {
        id: tile

        property string glyph
        property string title
        property string subtitle
        property bool on: false
        property bool chevron: false
        property bool expanded: false
        signal clicked

        implicitHeight: 50
        radius: Theme.radiusSm
        color: on ? Theme.accent : Theme.card

        Row {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 11
            spacing: 0

            StyledIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                text: tile.glyph
                font.pixelSize: 17
                color: tile.on ? Theme.accentInk : Theme.ink
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 26 - (tile.chevron ? 18 : 0)
                spacing: 0

                StyledText {
                    width: parent.width
                    text: tile.title
                    color: tile.on ? Theme.accentInk : Theme.ink
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                StyledText {
                    width: parent.width
                    text: tile.subtitle
                    color: tile.on ? Theme.accentInk : Theme.inkDim
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
            StyledIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: tile.chevron
                width: tile.chevron ? 18 : 0
                text: "󰅂"
                color: tile.on ? Theme.accentInk : Theme.inkDim
                rotation: tile.expanded ? 90 : 0

                Behavior on rotation {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }
            }
        }
        StateLayer {
            color: tile.on ? Theme.accentInk : Theme.ink
            onClicked: tile.clicked()
        }
    }

    // ── inline detail host ────────────────────────────────────────────────
    // Only the slot's height animates; the tiles below glide, and the card
    // grows with it.
    component Detail: Item {
        id: detail

        property string section
        readonly property bool open: win.expandedSection === section

        height: open ? 248 : 0
        clip: true
        visible: height > 0

        Behavior on height {
            Anim {
                type: Anim.Emphasized
            }
        }

        WifiDetail {
            width: parent.width
            height: 240
            opacity: detail.open ? 1 : 0
            live: detail.open

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    component ThemedSlider: Slider {
        id: s

        property color fill: Theme.accent
        property string knob
        property alias knobBtn: knobBtn
        signal knobClicked

        from: 0
        to: 1

        background: Item {
            StyledRect {
                x: s.knobBtn.width + 10
                y: s.height / 2 - 3
                width: s.availableWidth - s.knobBtn.width - 10
                height: 6
                radius: 999
                color: Theme.base02

                StyledRect {
                    width: s.visualPosition * parent.width
                    height: parent.height
                    radius: 999
                    color: s.fill
                }
            }
        }
        handle: StyledRect {
            x: knobBtn.width + 10 + s.visualPosition * (s.availableWidth - knobBtn.width - 10 - width)
            y: s.height / 2 - height / 2
            width: 14
            height: 14
            radius: 999
            color: Theme.base07
        }

        StyledRect {
            id: knobBtn

            width: 34
            height: 34
            radius: 999
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.card

            StyledIcon {
                anchors.centerIn: parent
                text: s.knob
                color: Theme.ink
                font.pixelSize: 15
            }
            StateLayer {
                onClicked: s.knobClicked()
            }
        }
    }

    component RoundButton: StyledRect {
        id: rb

        property string glyph
        property color hoverFg: Theme.accent
        signal clicked

        width: 32
        height: 32
        radius: 999
        color: Theme.card

        StyledIcon {
            anchors.centerIn: parent
            text: rb.glyph
            color: rbState.containsMouse ? rb.hoverFg : Theme.inkDim
            font.pixelSize: 16
        }
        StateLayer {
            id: rbState

            onClicked: rb.clicked()
        }
    }

    Elevation {
        anchors.fill: card
        radius: card.radius
        level: 4
    }

    StyledRect {
        id: card

        anchors.fill: parent
        radius: 20
        color: Theme.base00
        border.width: 1
        border.color: Theme.base02
        implicitHeight: layout.implicitHeight + 24

        Column {
            id: layout

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 10

            // ── header ──
            Item {
                width: parent.width
                height: 38

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9
                    height: 38

                    // ClippingRectangle clips children to the rounded shape, so
                    // the .face image is masked to a proper circle.
                    ClippingRectangle {
                        width: 34
                        height: 34
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.base02
                        border.width: 1
                        border.color: Theme.accent

                        Image {
                            anchors.fill: parent
                            source: Quickshell.env("HOME") + "/.face"
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 76
                            sourceSize.height: 76
                            visible: status === Image.Ready
                        }
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Quickshell.env("USER") || "user"
                        font.weight: Font.DemiBold
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    RoundButton {
                        glyph: "󰒓"
                        onClicked: Quickshell.execDetached(["pavucontrol"])
                    }
                    RoundButton {
                        glyph: "󰍁"
                        onClicked: {
                            win.close();
                            Quickshell.execDetached(["loginctl", "lock-session"]);
                        }
                    }
                    RoundButton {
                        glyph: "󰐥"
                        hoverFg: Theme.base08
                        onClicked: Popups.toggle("powermenu", win.screenName)
                    }
                }
            }

            StyledText {
                text: "Quick Controls"
                color: Theme.inkDim
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            // ── tiles ──
            // Rows are explicit (not a Grid) so the detail panel can slide in
            // directly under the row that owns the expanded tile.
            Column {
                id: tiles

                width: parent.width
                spacing: 0

                readonly property real tw: (width - 8) / 2

                Row {
                    spacing: 8
                    bottomPadding: 8

                    Tile {
                        width: tiles.tw
                        glyph: Net.icon
                        title: "Network"
                        subtitle: Net.label
                        chevron: true
                        on: Net.active
                        expanded: win.expandedSection === "wifi"
                        onClicked: win.expandedSection = win.expandedSection === "wifi" ? "" : "wifi"
                    }
                    Tile {
                        width: tiles.tw
                        glyph: "󰂯"
                        title: "Bluetooth"
                        subtitle: {
                            if (!win.adapter || !win.adapter.enabled)
                                return "Off";
                            const d = win.adapter.devices ? win.adapter.devices.values.find(x => x.connected) : null;
                            return d ? d.name : "On";
                        }
                        on: win.adapter && win.adapter.enabled
                        onClicked: {
                            if (win.adapter)
                                win.adapter.enabled = !win.adapter.enabled;
                        }
                    }
                }

                Detail {
                    width: parent.width
                    section: "wifi"
                }

                Row {
                    spacing: 8
                    bottomPadding: 8

                    Tile {
                        width: tiles.tw
                        glyph: "󰀝"
                        title: "Airplane"
                        subtitle: Radios.airplaneOn ? "On" : "Off"
                        on: Radios.airplaneOn
                        onClicked: Radios.toggle()
                    }
                    Tile {
                        id: micTile

                        readonly property bool micMuted: Audio.source && Audio.source.audio ? Audio.source.audio.muted : true

                        width: tiles.tw
                        glyph: micMuted ? "󰍭" : "󰍬"
                        title: "Microphone"
                        subtitle: micMuted ? "Muted" : "Active"
                        on: !micMuted
                        onClicked: {
                            if (Audio.source && Audio.source.audio)
                                Audio.source.audio.muted = !Audio.source.audio.muted;
                        }
                    }
                }

                Row {
                    spacing: 8

                    Tile {
                        width: tiles.tw
                        glyph: "󰂛"
                        title: "Do Not Disturb"
                        subtitle: Notif.dnd ? "On" : "Off"
                        on: Notif.dnd
                        onClicked: Notif.toggleDnd()
                    }
                    Tile {
                        width: tiles.tw
                        glyph: Audio.muted ? "󰖁" : "󰕾"
                        title: "Volume"
                        subtitle: Audio.percent + "%"
                        on: !Audio.muted
                        onClicked: Audio.toggleMute()
                    }
                }
            }

            // ── sliders ──
            ThemedSlider {
                width: parent.width
                height: 36
                fill: Theme.accent
                knob: Audio.muted ? "󰖁" : "󰕾"
                value: Audio.volume
                onMoved: Audio.setVolume(value)
                onKnobClicked: Audio.toggleMute()
            }
            ThemedSlider {
                width: parent.width
                height: 36
                visible: Brightness.available
                fill: Theme.base0A
                knob: "󰃢"
                value: Brightness.value
                onMoved: Brightness.set(value)
            }

            // ── media player ──
            StyledRect {
                width: parent.width
                visible: win.player !== null
                implicitHeight: 58
                radius: Theme.radiusSm
                color: Theme.card
                border.width: 1
                border.color: Theme.base02

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    ClippingRectangle {
                        width: 38
                        height: 38
                        radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.base02

                        Image {
                            anchors.fill: parent
                            source: win.player ? (win.player.trackArtUrl || "") : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                            // Album art is routinely 1000px square for a 38px slot.
                            sourceSize.width: 76
                            sourceSize.height: 76
                        }
                    }
                    Column {
                        width: parent.width - 38 - ctlRow.width - 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        ScrollingText {
                            width: parent.width
                            text: win.player ? (win.player.trackTitle || "Unknown") : ""
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            width: parent.width
                            text: win.player ? (win.player.trackArtist || "") : ""
                            color: Theme.inkDim
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                    Row {
                        id: ctlRow

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Repeater {
                            model: ["prev", "toggle", "next"]

                            delegate: StyledRect {
                                id: mediaBtn

                                required property var modelData

                                readonly property bool isPlay: modelData === "toggle"

                                width: 30
                                height: 30
                                radius: 999
                                color: "transparent"

                                StyledIcon {
                                    anchors.centerIn: parent
                                    text: mediaBtn.isPlay ? (win.player && win.player.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊") : (mediaBtn.modelData === "prev" ? "󰒮" : "󰒭")
                                    font.pixelSize: mediaBtn.isPlay ? 17 : 15
                                    color: mediaBtn.isPlay || mediaState.containsMouse ? Theme.accent : Theme.inkDim
                                }
                                StateLayer {
                                    id: mediaState

                                    onClicked: {
                                        if (!win.player)
                                            return;
                                        if (mediaBtn.modelData === "prev")
                                            win.player.previous();
                                        else if (mediaBtn.modelData === "next")
                                            win.player.next();
                                        else
                                            win.player.togglePlaying();
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

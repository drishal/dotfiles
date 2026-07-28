import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Bluetooth
import Quickshell.Widgets
import qs.Common
import qs.Services

// Quick-settings control center, top-right (mirrors ags Dashboard).
// Tiles (network/bluetooth/airplane/mic/DND/volume), volume+brightness
// sliders, and the mpris media player (mpv preferred).

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property string screenName: screen ? screen.name : ""

    visible: Popups.isOpen("dashboard", win.screenName)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0
    anchors.top: true
    anchors.right: true
    implicitWidth: 420
    // While open the window is held at the size the card would need with a
    // detail expanded, so expanding/collapsing never resizes the layer-shell
    // surface — per-frame resizes stutter, and the final one flickers. Input is
    // masked to the card so the reserved-but-empty strip stays click-through.
    property real holdHeight: 0
    implicitHeight: Math.max(card.implicitHeight + 16, holdHeight)
    mask: Region {
        item: card
    }

    // Inline detail panel below the tiles ("" = collapsed), DMS-style.
    property string expandedSection: ""
    onVisibleChanged: {
        if (visible) {
            holdHeight = card.implicitHeight + 16 + 248;
        } else {
            holdHeight = 0;
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
    component Tile: Rectangle {
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
        color: on ? Theme.accent : (tma.containsMouse ? Theme.cardHi : Theme.card)
        Row {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 11
            spacing: 0
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                text: tile.glyph
                font.family: Theme.fontMono
                font.pixelSize: 17
                color: tile.on ? Theme.accentInk : Theme.ink
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 26 - (tile.chevron ? 18 : 0)
                spacing: 0
                Text {
                    width: parent.width
                    text: tile.title
                    color: tile.on ? Theme.accentInk : Theme.ink
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: tile.subtitle
                    color: tile.on ? Theme.accentInk : Theme.inkDim
                    font.family: Theme.fontSans
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: tile.chevron
                width: tile.chevron ? 18 : 0
                text: "󰅂"
                font.family: Theme.fontMono
                font.pixelSize: 14
                color: tile.on ? Theme.accentInk : Theme.inkDim
                rotation: tile.expanded ? 90 : 0
                Behavior on rotation {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
        MouseArea {
            id: tma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }

    // ── inline detail host ────────────────────────────────────────────────
    // Only the slot's height animates, so the tiles below glide instead of
    // jumping; the card grows into space the window already reserved.
    component Detail: Item {
        id: detail
        property string section
        readonly property bool open: win.expandedSection === section
        height: 0
        clip: true
        visible: height > 0

        onOpenChanged: {
            slide.to = open ? 248 : 0;
            slide.restart();
        }

        NumberAnimation {
            id: slide
            target: detail
            property: "height"
            duration: 220
            easing.type: Easing.OutCubic
        }

        WifiDetail {
            width: parent.width
            height: 240
            opacity: detail.open ? 1 : 0
            live: detail.open

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                }
            }
        }
    }

    component ThemedSlider: Slider {
        id: s
        property color fill: Theme.accent
        property string knob
        signal knobClicked
        from: 0
        to: 1
        background: Item {
            Rectangle {
                x: s.knobBtn.width + 10
                y: s.height / 2 - 3
                width: s.availableWidth - s.knobBtn.width - 10
                height: 6
                radius: 999
                color: Theme.base02
                Rectangle {
                    width: s.visualPosition * parent.width
                    height: parent.height
                    radius: 999
                    color: s.fill
                }
            }
        }
        property alias knobBtn: knobBtn
        Rectangle {
            id: knobBtn
            width: 34
            height: 34
            radius: 999
            anchors.verticalCenter: parent.verticalCenter
            color: kma.containsMouse ? Theme.cardHi : Theme.card
            Text {
                anchors.centerIn: parent
                text: s.knob
                font.family: Theme.fontMono
                font.pixelSize: 15
                color: Theme.ink
            }
            MouseArea {
                id: kma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: s.knobClicked()
            }
        }
        handle: Rectangle {
            x: knobBtn.width + 10 + s.visualPosition * (s.availableWidth - knobBtn.width - 10 - width)
            y: s.height / 2 - height / 2
            width: 14
            height: 14
            radius: 999
            color: Theme.base07
        }
    }

    Rectangle {
        id: card
        // Sized to its content, not to the window: while `holdHeight` pins the
        // window through a transition, a card filling it would keep the
        // background at full size and snap when the hold releases.
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        height: implicitHeight
        radius: 20
        color: Theme.base00
        border.width: 1
        border.color: Theme.base02
        focus: win.visible
        Keys.onEscapePressed: Popups.close("dashboard", win.screenName)
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
                    // ClippingRectangle clips its children to the rounded shape,
                    // so the .face image is masked to a proper circle (a plain
                    // Rectangle + clip:true would only clip a square).
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
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "drishal"
                        color: Theme.ink
                        font.family: Theme.fontSans
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Repeater {
                        model: [
                            {
                                g: "󰒓",
                                cmd: "pavucontrol"
                            },
                            {
                                g: "󰍁",
                                cmd: "loginctl lock-session"
                            }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: 32
                            height: 32
                            radius: 999
                            color: hma.containsMouse ? Theme.cardHi : Theme.card
                            Text {
                                anchors.centerIn: parent
                                text: modelData.g
                                font.family: Theme.fontMono
                                font.pixelSize: 16
                                color: hma.containsMouse ? Theme.accent : Theme.inkDim
                            }
                            MouseArea {
                                id: hma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["bash", "-c", parent.modelData.cmd])
                            }
                        }
                    }
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 999
                        color: pma.containsMouse ? Theme.cardHi : Theme.card
                        Text {
                            anchors.centerIn: parent
                            text: "󰐥"
                            font.family: Theme.fontMono
                            font.pixelSize: 16
                            color: pma.containsMouse ? Theme.accent : Theme.inkDim
                        }
                        MouseArea {
                            id: pma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Popups.toggle("powermenu", win.screenName)
                        }
                    }
                }
            }

            Text {
                text: "Quick Controls"
                color: Theme.inkDim
                font.family: Theme.fontSans
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            // ── tiles ──
            // Rows are explicit (not a Grid) so the detail panel can slide in
            // directly under the row that owns the expanded tile, DMS-style.
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
                    id: netDetail
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
                        width: tiles.tw
                        readonly property bool micMuted: Audio.source && Audio.source.audio ? Audio.source.audio.muted : true
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
            Rectangle {
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
                    Rectangle {
                        width: 38
                        height: 38
                        radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.base02
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: win.player ? (win.player.trackArtUrl || "") : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                    }
                    Column {
                        width: parent.width - 38 - ctlRow.width - 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            width: parent.width
                            text: win.player ? (win.player.trackTitle || "Unknown") : ""
                            color: Theme.ink
                            font.family: Theme.fontSans
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: win.player ? (win.player.trackArtist || "") : ""
                            color: Theme.inkDim
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                    Row {
                        id: ctlRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: [
                                {
                                    g: "󰒮",
                                    a: "prev"
                                },
                                {
                                    g: "play",
                                    a: "toggle"
                                },
                                {
                                    g: "󰒭",
                                    a: "next"
                                }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool isPlay: modelData.a === "toggle"
                                width: 30
                                height: 30
                                radius: 999
                                color: cma.containsMouse ? Theme.cardHi : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: isPlay ? (win.player && win.player.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊") : modelData.g
                                    font.family: Theme.fontMono
                                    font.pixelSize: isPlay ? 17 : 15
                                    color: isPlay ? Theme.accent : (cma.containsMouse ? Theme.accent : Theme.inkDim)
                                }
                                MouseArea {
                                    id: cma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!win.player)
                                            return;
                                        if (modelData.a === "prev")
                                            win.player.previous();
                                        else if (modelData.a === "next")
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

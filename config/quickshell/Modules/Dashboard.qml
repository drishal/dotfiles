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
    implicitWidth: 540
    implicitHeight: card.implicitHeight + 16

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
        signal clicked
        implicitHeight: 62
        radius: Theme.radiusSm
        color: on ? Theme.accent : (tma.containsMouse ? Theme.cardHi : Theme.card)
        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 0
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                text: tile.glyph
                font.family: Theme.fontMono
                font.pixelSize: 20
                color: tile.on ? Theme.accentInk : Theme.ink
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 32 - (tile.chevron ? 22 : 0)
                spacing: 1
                Text {
                    width: parent.width
                    text: tile.title
                    color: tile.on ? Theme.accentInk : Theme.ink
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: tile.subtitle
                    color: tile.on ? Theme.accentInk : Theme.inkDim
                    font.family: Theme.fontSans
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: tile.chevron
                width: tile.chevron ? 22 : 0
                text: "󰅂"
                font.family: Theme.fontMono
                font.pixelSize: 16
                color: tile.on ? Theme.accentInk : Theme.inkDim
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

    component ThemedSlider: Slider {
        id: s
        property color fill: Theme.accent
        property string knob
        signal knobClicked
        from: 0
        to: 1
        background: Item {
            Rectangle {
                x: s.knobBtn.width + 12
                y: s.height / 2 - 4
                width: s.availableWidth - s.knobBtn.width - 12
                height: 8
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
            width: 40
            height: 40
            radius: 999
            anchors.verticalCenter: parent.verticalCenter
            color: kma.containsMouse ? Theme.cardHi : Theme.card
            Text {
                anchors.centerIn: parent
                text: s.knob
                font.family: Theme.fontMono
                font.pixelSize: 17
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
            x: knobBtn.width + 12 + s.visualPosition * (s.availableWidth - knobBtn.width - 12 - width)
            y: s.height / 2 - height / 2
            width: 16
            height: 16
            radius: 999
            color: Theme.base07
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 8
        radius: 24
        color: Theme.base00
        border.width: 1
        border.color: Theme.base02
        focus: win.visible
        Keys.onEscapePressed: Popups.close("dashboard", win.screenName)
        implicitHeight: layout.implicitHeight + 28

        Column {
            id: layout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14
            spacing: 14

            // ── header ──
            Item {
                width: parent.width
                height: 48
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    height: 48
                    // ClippingRectangle clips its children to the rounded shape,
                    // so the .face image is masked to a proper circle (a plain
                    // Rectangle + clip:true would only clip a square).
                    ClippingRectangle {
                        width: 38
                        height: 38
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
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
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
                            width: 38
                            height: 38
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
                        width: 38
                        height: 38
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
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            // ── tiles ──
            Grid {
                width: parent.width
                columns: 3
                columnSpacing: 10
                rowSpacing: 10
                readonly property real tw: (width - 2 * 10) / 3

                Tile {
                    width: parent.tw
                    glyph: Net.icon
                    title: "Network"
                    subtitle: Net.label
                    chevron: true
                    on: Net.active
                    onClicked: Quickshell.execDetached(["nm-connection-editor"])
                }
                Tile {
                    width: parent.tw
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
                Tile {
                    width: parent.tw
                    glyph: "󰀝"
                    title: "Airplane"
                    subtitle: Radios.airplaneOn ? "On" : "Off"
                    on: Radios.airplaneOn
                    onClicked: Radios.toggle()
                }
                Tile {
                    width: parent.tw
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
                Tile {
                    width: parent.tw
                    glyph: "󰂛"
                    title: "Do Not Disturb"
                    subtitle: Notif.dnd ? "On" : "Off"
                    on: Notif.dnd
                    onClicked: Notif.toggleDnd()
                }
                Tile {
                    width: parent.tw
                    glyph: Audio.muted ? "󰖁" : "󰕾"
                    title: "Volume"
                    subtitle: Audio.percent + "%"
                    on: !Audio.muted
                    onClicked: Audio.toggleMute()
                }
            }

            // ── sliders ──
            ThemedSlider {
                width: parent.width
                height: 44
                fill: Theme.accent
                knob: Audio.muted ? "󰖁" : "󰕾"
                value: Audio.volume
                onMoved: Audio.setVolume(value)
                onKnobClicked: Audio.toggleMute()
            }
            ThemedSlider {
                width: parent.width
                height: 44
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
                implicitHeight: 68
                radius: Theme.radiusSm
                color: Theme.card
                border.width: 1
                border.color: Theme.base02

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    Rectangle {
                        width: 44
                        height: 44
                        radius: 12
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
                        width: parent.width - 44 - ctlRow.width - 24
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

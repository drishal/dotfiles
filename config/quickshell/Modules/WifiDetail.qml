import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services

// Expandable wifi panel for the dashboard's Network tile (DMS control-center
// pattern: the tile's chevron reveals an inline detail view instead of a
// separate window). Scan list + connect/disconnect/forget, all via Net/nmcli.

Rectangle {
    id: root

    property bool live: false // panel expanded — only then do we scan
    property string pendingSsid: "" // ssid whose password prompt is open

    radius: Theme.radiusSm
    color: Theme.card
    border.width: 1
    border.color: Theme.base02
    clip: true

    // Only scan while the panel is expanded, and start after the slide so the
    // nmcli round-trip can't land mid-animation.
    onLiveChanged: {
        if (live) {
            refTimer.start();
        } else {
            refTimer.stop();
            if (held) {
                held = false;
                Net.removeRef();
            }
            pendingSsid = "";
        }
    }
    property bool held: false
    Component.onDestruction: if (held) Net.removeRef()

    Timer {
        id: refTimer
        interval: 240
        onTriggered: {
            root.held = true;
            Net.addRef();
        }
    }

    function activate(n) {
        if (n.active)
            Net.disconnect(n.ssid);
        else if (n.saved || !n.secured)
            Net.connect(n.ssid, "");
        else
            root.pendingSsid = root.pendingSsid === n.ssid ? "" : n.ssid;
    }

    component IconButton: Rectangle {
        id: btn
        property string glyph
        property bool spinning: false
        signal clicked
        width: 26
        height: 26
        radius: 999
        color: ma.containsMouse ? Theme.cardHi : "transparent"
        Text {
            id: gt
            anchors.centerIn: parent
            text: btn.glyph
            font.family: Theme.fontMono
            font.pixelSize: 14
            color: ma.containsMouse ? Theme.accent : Theme.inkDim
            RotationAnimator on rotation {
                running: btn.spinning
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 1000
            }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    Column {
        id: body
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        Item {
            width: parent.width
            height: 26
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Wi-Fi"
                color: Theme.ink
                font.family: Theme.fontSans
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                IconButton {
                    glyph: "󰑐"
                    spinning: Net.scanning
                    visible: Net.wifiEnabled
                    onClicked: Net.scan(true)
                }
                IconButton {
                    glyph: Net.wifiEnabled ? "󰤨" : "󰤭"
                    onClicked: Net.toggleWifi()
                }
                IconButton {
                    glyph: "󰒓"
                    onClicked: Quickshell.execDetached(["nm-connection-editor"])
                }
            }
        }

        // ── radio off ──
        Item {
            width: parent.width
            height: body.height - 26 - body.spacing
            visible: !Net.wifiEnabled
            Column {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰖪"
                    font.family: Theme.fontMono
                    font.pixelSize: 26
                    color: Theme.inkDim
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Net.wifiPresent ? "Wi-Fi is off" : "No Wi-Fi adapter"
                    color: Theme.inkDim
                    font.family: Theme.fontSans
                    font.pixelSize: 11
                }
            }
        }

        // ── network list ──
        Flickable {
            width: parent.width
            height: body.height - 26 - body.spacing - (errText.visible ? errText.height + body.spacing : 0)
            visible: Net.wifiEnabled
            contentHeight: listCol.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            Column {
                id: listCol
                width: parent.width
                spacing: 3

                Text {
                    visible: Net.networks.length === 0
                    text: Net.scanning ? "Scanning…" : "No networks found"
                    color: Theme.inkDim
                    font.family: Theme.fontSans
                    font.pixelSize: 11
                    topPadding: 8
                }

                Repeater {
                    model: Net.networks
                    delegate: Column {
                        required property var modelData
                        width: listCol.width
                        spacing: 3

                        Rectangle {
                            width: parent.width
                            height: 34
                            radius: 10
                            color: modelData.active ? Theme.accent : (nma.containsMouse ? Theme.cardHi : "transparent")

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 18
                                    text: Net.signalIcon(modelData.signal)
                                    font.family: Theme.fontMono
                                    font.pixelSize: 14
                                    color: modelData.active ? Theme.accentInk : Theme.ink
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 18 - 8 * 3 - actions.width
                                    text: modelData.ssid
                                    elide: Text.ElideRight
                                    color: modelData.active ? Theme.accentInk : Theme.ink
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                    font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                }
                                Row {
                                    id: actions
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: modelData.secured
                                        text: "󰌾"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        color: modelData.active ? Theme.accentInk : Theme.inkDim
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: Net.busySsid === modelData.ssid
                                        text: "󰔟"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        color: modelData.active ? Theme.accentInk : Theme.inkDim
                                    }
                                    IconButton {
                                        visible: modelData.saved
                                        glyph: "󰆴"
                                        onClicked: Net.forget(modelData.ssid)
                                    }
                                }
                            }

                            MouseArea {
                                id: nma
                                anchors.fill: parent
                                anchors.rightMargin: actions.width + 8
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activate(modelData)
                            }
                        }

                        // ── inline password prompt ──
                        Row {
                            width: parent.width
                            height: visible ? 30 : 0
                            visible: root.pendingSsid === modelData.ssid
                            spacing: 6

                            Rectangle {
                                width: parent.width - 62
                                height: 30
                                radius: 8
                                color: Theme.base00
                                border.width: 1
                                border.color: pw.activeFocus ? Theme.accent : Theme.base02
                                TextField {
                                    id: pw
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    background: null
                                    echoMode: TextInput.Password
                                    placeholderText: "Password"
                                    placeholderTextColor: Theme.inkDim
                                    color: Theme.ink
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    onVisibleChanged: if (visible) forceActiveFocus()
                                    onAccepted: {
                                        Net.connect(modelData.ssid, text);
                                        text = "";
                                        root.pendingSsid = "";
                                    }
                                }
                            }
                            Rectangle {
                                width: 56
                                height: 30
                                radius: 8
                                color: cma.containsMouse ? Theme.accent : Theme.cardHi
                                Text {
                                    anchors.centerIn: parent
                                    text: "Connect"
                                    color: cma.containsMouse ? Theme.accentInk : Theme.ink
                                    font.family: Theme.fontSans
                                    font.pixelSize: 10
                                }
                                MouseArea {
                                    id: cma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: pw.accepted()
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            id: errText
            width: parent.width
            visible: Net.error !== ""
            text: Net.error
            color: Theme.base08
            font.family: Theme.fontSans
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }
}

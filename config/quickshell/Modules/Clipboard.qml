import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services

// cliphist clipboard history, top-right (mirrors ags Clipboard). Search field,
// numbered rows with image thumbnails / text preview, per-row delete, wipe-all.

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property string screenName: screen ? screen.name : ""

    visible: Popups.isOpen("clipboard", win.screenName)
    onVisibleChanged: {
        if (visible) {
            Clip.query = "";
            search.text = "";
            Clip.refresh();
            search.forceActiveFocus();
        }
    }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0
    anchors.top: true
    anchors.right: true
    implicitWidth: 580
    implicitHeight: card.height + 16

    Rectangle {
        id: card
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        width: 560
        height: 640
        radius: 22
        color: Theme.base00
        border.width: 1
        border.color: Theme.base02
        focus: win.visible
        Keys.onEscapePressed: Popups.close("clipboard", win.screenName)

        // Drives the staggered row slide-out; the timer waits for the last row
        // to finish before actually wiping the history.
        property bool clearing: false
        Timer {
            id: wipeTimer
            onTriggered: {
                Clip.wipe();
                card.clearing = false;
            }
        }
        Connections {
            target: win
            function onVisibleChanged() {
                if (!win.visible) {
                    wipeTimer.stop();
                    card.clearing = false;
                }
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // header
            Row {
                width: parent.width
                spacing: 0
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    text: "󰅍"
                    font.family: Theme.fontMono
                    font.pixelSize: 20
                    color: Theme.accent
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 34 - 40 - 40
                    text: "Clipboard History (" + Clip.count + ")"
                    color: Theme.ink
                    font.family: Theme.fontSans
                    font.pixelSize: 17
                    font.weight: Font.Bold
                }
                Rectangle {
                    width: 34
                    height: 34
                    radius: 999
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: card.clearing ? 0.5 : 1
                    color: (wipeMa.containsMouse && !card.clearing) ? Theme.card : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰩹"
                        font.family: Theme.fontMono
                        font.pixelSize: 17
                        color: (wipeMa.containsMouse && !card.clearing) ? Theme.base08 : Theme.inkDim
                    }
                    MouseArea {
                        id: wipeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (card.clearing || Clip.count === 0)
                                return;
                            card.clearing = true;
                            wipeTimer.interval = (Clip.filtered.length - 1) * 50 + 350 + 80;
                            wipeTimer.restart();
                        }
                    }
                }
                Rectangle {
                    width: 34
                    height: 34
                    radius: 999
                    anchors.verticalCenter: parent.verticalCenter
                    color: closeMa.containsMouse ? Theme.card : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.fontMono
                        font.pixelSize: 17
                        color: closeMa.containsMouse ? Theme.accent : Theme.inkDim
                    }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Popups.close("clipboard", win.screenName)
                    }
                }
            }

            // search
            Rectangle {
                width: parent.width
                height: 44
                radius: 999
                color: Theme.card
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        font.family: Theme.fontMono
                        font.pixelSize: 16
                        color: Theme.inkDim
                    }
                    TextField {
                        id: search
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 30
                        placeholderText: "Search clipboard…"
                        color: Theme.ink
                        font.family: Theme.fontSans
                        font.pixelSize: 14
                        background: null
                        onTextChanged: Clip.query = text
                        Keys.onEscapePressed: Popups.close("clipboard", win.screenName)
                    }
                }
            }

            // list
            ScrollView {
                id: clipScroll
                width: parent.width
                height: parent.height - 44 - 34 - 24 - 24
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    // ScrollView viewport width (parent.width would be ~0 here).
                    width: clipScroll.availableWidth
                    spacing: 8

                    Repeater {
                        model: Clip.filtered
                        delegate: Rectangle {
                            id: crow
                            required property var modelData
                            required property int index
                            width: parent.width - 4
                            radius: 14
                            color: crma.containsMouse ? Theme.cardHi : Theme.card
                            border.width: crma.containsMouse ? 1 : 0
                            border.color: Theme.accent
                            implicitHeight: 68

                            // Staggered slide-out on Wipe: rows glide off to the
                            // right + fade, delayed by position (mirrors ags
                            // .clip-row.clearing-out).
                            transform: Translate {
                                id: crowSlide
                            }
                            states: State {
                                name: "clearing"
                                when: card.clearing
                                PropertyChanges {
                                    target: crowSlide
                                    x: 600
                                }
                                PropertyChanges {
                                    target: crow
                                    opacity: 0
                                }
                            }
                            transitions: Transition {
                                to: "clearing"
                                SequentialAnimation {
                                    PauseAnimation {
                                        duration: crow.index * 50
                                    }
                                    ParallelAnimation {
                                        NumberAnimation {
                                            target: crowSlide
                                            property: "x"
                                            duration: 350
                                            easing.type: Easing.InCubic
                                        }
                                        NumberAnimation {
                                            target: crow
                                            property: "opacity"
                                            duration: 350
                                            easing.type: Easing.InCubic
                                        }
                                    }
                                }
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.right: delBtn.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                spacing: 12

                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 999
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.base02
                                    Text {
                                        anchors.centerIn: parent
                                        text: crow.index + 1
                                        font.family: Theme.fontSans
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        color: Theme.accent
                                    }
                                }

                                // thumbnail (image) or glyph (text)
                                Image {
                                    visible: crow.modelData.isImage
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: crow.modelData.isImage ? 60 : 0
                                    height: 44
                                    source: crow.modelData.isImage ? ("file://" + crow.modelData.thumb) : ""
                                    fillMode: Image.PreserveAspectFit
                                    cache: false
                                }
                                Text {
                                    visible: !crow.modelData.isImage
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: crow.modelData.isImage ? 0 : 44
                                    text: "󰅎"
                                    horizontalAlignment: Text.AlignHCenter
                                    font.family: Theme.fontMono
                                    font.pixelSize: 20
                                    color: Theme.inkDim
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: crow.width - 30 - (crow.modelData.isImage ? 60 : 44) - delBtn.width - 60
                                    spacing: 2
                                    Text {
                                        width: parent.width
                                        text: crow.modelData.isImage ? ("Image • " + crow.modelData.dimensions + " " + crow.modelData.imageType.toUpperCase()) : "Text"
                                        color: Theme.accent
                                        font.family: Theme.fontSans
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        width: parent.width
                                        text: crow.modelData.preview
                                        color: Theme.inkDim
                                        font.family: Theme.fontSans
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                            }

                            MouseArea {
                                id: crma
                                anchors.left: parent.left
                                anchors.right: delBtn.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Clip.copy(crow.modelData);
                                    Popups.close("clipboard", win.screenName);
                                }
                            }

                            Rectangle {
                                id: delBtn
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.rightMargin: 8
                                width: 36
                                height: 36
                                radius: 999
                                color: delMa.containsMouse ? Theme.base02 : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 15
                                    color: delMa.containsMouse ? Theme.base08 : Theme.inkDim
                                }
                                MouseArea {
                                    id: delMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Clip.remove(crow.modelData)
                                }
                            }
                        }
                    }

                    // empty state
                    Column {
                        width: parent.width
                        visible: Clip.count === 0
                        topPadding: 160
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰅎"
                            font.family: Theme.fontMono
                            font.pixelSize: 34
                            color: Theme.base03
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Clipboard is empty"
                            color: Theme.inkDim
                            font.family: Theme.fontSans
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services

// Toast-style volume OSD, bottom-center (mirrors ags VolumePopup). Fires
// whenever the active physical output's volume/mute changes (media keys,
// dashboard slider, app control) via Audio.changePulse — never on startup.

PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    property bool showing: false
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0
    anchors.bottom: true
    implicitWidth: card.width
    implicitHeight: card.height + 64
    visible: showing

    readonly property string icon: {
        if (Audio.muted)
            return "󰖁";
        const p = Audio.percent;
        if (p === 0)
            return "󰝟";
        if (p <= 33)
            return "󰕿";
        if (p <= 66)
            return "󰖀";
        return "󰕾";
    }

    Timer {
        id: hideTimer
        interval: 1800
        onTriggered: win.showing = false
    }

    Connections {
        target: Audio
        function onChangePulseChanged() {
            win.showing = true;
            hideTimer.restart();
        }
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 64
        width: inner.implicitWidth + 36
        height: inner.implicitHeight + 20
        radius: 16
        color: Theme.base00
        border.width: 1
        border.color: Theme.base02

        Row {
            id: inner
            anchors.centerIn: parent
            spacing: 12
            width: 280

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: win.icon
                font.family: Theme.fontMono
                font.pixelSize: 22
                color: Audio.muted ? Theme.base08 : Theme.accent
            }
            Slider {
                id: slider
                anchors.verticalCenter: parent.verticalCenter
                width: 180
                from: 0
                to: 1
                value: Audio.volume
                onMoved: Audio.setVolume(value)
                background: Rectangle {
                    x: slider.leftPadding
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: slider.availableWidth
                    height: 8
                    radius: 999
                    color: Theme.base02
                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        radius: 999
                        color: Theme.accent
                    }
                }
                handle: Rectangle {
                    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: 16
                    height: 16
                    radius: 999
                    color: Theme.base07
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.muted ? "Muted" : Audio.percent + "%"
                font.family: Theme.fontSans
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Audio.muted ? Theme.base08 : Theme.ink
                width: 42
            }
        }
    }
}

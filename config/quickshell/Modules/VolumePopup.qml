pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services

// Toast-style volume OSD, bottom-centre. Fires whenever the active physical
// output's volume/mute changes (media keys, dashboard slider, app control) via
// Audio.changePulse — never on startup.

Panel {
    id: win

    property bool showing: false

    shown: showing
    slideFrom: Qt.BottomEdge

    width: card.width
    height: card.height

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

    Elevation {
        anchors.fill: card
        radius: card.radius
        level: 3
    }

    StyledRect {
        id: card

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

            StyledIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: win.icon
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

                background: StyledRect {
                    x: slider.leftPadding
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: slider.availableWidth
                    height: 8
                    radius: 999
                    color: Theme.base02

                    StyledRect {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        radius: 999
                        color: Theme.accent
                    }
                }
                handle: StyledRect {
                    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: 16
                    height: 16
                    radius: 999
                    color: Theme.base07
                }
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.muted ? "Muted" : Audio.percent + "%"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Audio.muted ? Theme.base08 : Theme.ink
                width: 42
                animate: true
            }
        }
    }
}

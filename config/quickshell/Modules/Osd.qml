pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services

// Toast-style OSD, bottom-centre, for volume and brightness. Fires on
// Audio.changePulse (media keys, dashboard slider, app control) and
// Brightness.changePulse (keybind IPC, dashboard slider) — never on startup.
// Switching kind while it is up swaps the contents in place.

Panel {
    id: win

    property bool showing: false
    property string kind: "volume"
    readonly property bool isVolume: kind === "volume"

    shown: showing
    attached: false
    slideFrom: Qt.BottomEdge

    width: card.width
    height: card.height

    readonly property real level: isVolume ? Audio.volume : Brightness.value
    readonly property bool off: isVolume && Audio.muted

    readonly property string icon: {
        if (!isVolume) {
            const b = Brightness.value;
            return b <= 0.33 ? "󰃞" : b <= 0.66 ? "󰃟" : "󰃠";
        }
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

    function pulse(k) {
        win.kind = k;
        win.showing = true;
        hideTimer.restart();
    }

    Connections {
        target: Audio

        function onChangePulseChanged() {
            win.pulse("volume");
        }
    }
    Connections {
        target: Brightness

        function onChangePulseChanged() {
            win.pulse("brightness");
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
                color: win.off ? Theme.base08 : Theme.accent
            }
            Slider {
                id: slider

                anchors.verticalCenter: parent.verticalCenter
                width: 180
                from: 0
                to: 1
                value: win.level
                onMoved: win.isVolume ? Audio.setVolume(value) : Brightness.set(value)

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
                text: win.off ? "Muted" : win.isVolume ? Audio.percent + "%" : Math.round(Brightness.value * 100) + "%"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: win.off ? Theme.base08 : Theme.ink
                width: 42
                animate: true
            }
        }
    }
}

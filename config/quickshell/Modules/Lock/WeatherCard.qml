import QtQuick
import qs.Common
import qs.Services

Card {
    id: root

    readonly property var cur: Weather.current
    readonly property var info: cur ? Weather.wmoInfo(cur.weatherCode, cur.isDay) : null

    implicitHeight: 96

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        visible: Weather.status !== "ready" || !root.cur
        text: Weather.status === "error" ? "Weather unavailable" : "Loading weather…"
        color: Weather.status === "error" ? Theme.base08 : Theme.inkDim
        font.pixelSize: 12
    }

    Row {
        anchors.fill: parent
        visible: Weather.status === "ready" && root.cur
        spacing: 14

        StyledIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.info ? root.info.icon : ""
            color: Theme.base0A
            font.pixelSize: 40
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            StyledText {
                text: root.cur ? root.cur.temp + "°C" : ""
                color: Theme.base07
                font.pixelSize: 26
                font.weight: Font.DemiBold
            }
            StyledText {
                text: root.info ? root.info.desc : ""
                color: Theme.base06
                font.pixelSize: 12
            }
            StyledText {
                text: Weather.locationName + (root.cur ? "  •  feels " + root.cur.feelsLike + "°" : "")
                color: Theme.inkDim
                font.pixelSize: 11
            }
        }
    }
}

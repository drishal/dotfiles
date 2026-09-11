import QtQuick
import qs.Common
import qs.Services

// Sys polls whether or not anything is displaying it, so unlike the process
// list this needs no ref-counting.
Card {
    id: root

    implicitHeight: col.implicitHeight + padding * 2

    component Meter: Column {
        id: meter

        property string label
        property string value
        property real fraction: 0
        property color fill: Theme.accent

        spacing: 5

        Item {
            width: meter.width
            height: 15

            StyledText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: meter.label
                color: Theme.inkDim
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }
            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: meter.value
                font.pixelSize: 11
                animate: true
            }
        }
        StyledRect {
            width: meter.width
            height: 6
            radius: 999
            color: Theme.base02

            StyledRect {
                width: parent.width * Math.max(0, Math.min(1, meter.fraction))
                height: parent.height
                radius: 999
                color: meter.fill

                Behavior on width {
                    Anim {
                        type: Anim.Emphasized
                    }
                }
            }
        }
    }

    Column {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 12

        Meter {
            width: parent.width
            label: "CPU"
            value: Sys.cpu + "%"
            fraction: Sys.cpu / 100
            fill: Sys.cpu >= 85 ? Theme.base08 : Theme.base0C
        }

        // One column per thread — on a many-core box the shape of the load says
        // more than the average.
        Row {
            width: parent.width
            height: 20
            spacing: Math.max(1, (width - Sys.cores.length * 3) / Math.max(1, Sys.cores.length - 1))

            Repeater {
                model: Sys.cores

                delegate: Item {
                    required property var modelData

                    width: 3
                    height: 20

                    StyledRect {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(2, parent.height * modelData / 100)
                        radius: 2
                        color: modelData >= 85 ? Theme.base08 : Theme.base0C

                        Behavior on height {
                            Anim {
                                type: Anim.Emphasized
                            }
                        }
                    }
                }
            }
        }

        Meter {
            width: parent.width
            label: "MEMORY"
            value: Sys.memUsedGb.toFixed(1) + " / " + Sys.memTotalGb.toFixed(0) + " G"
            fraction: Sys.memPercent / 100
            fill: Sys.memPercent >= 90 ? Theme.base08 : Theme.base09
        }

        Meter {
            width: parent.width
            visible: Sys.swapTotalGb > 0
            label: "SWAP"
            value: Sys.swapUsedGb.toFixed(1) + " / " + Sys.swapTotalGb.toFixed(0) + " G"
            fraction: Sys.swapPercent / 100
            fill: Theme.base0E
        }

        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "load  " + Sys.loadAvg.map(v => v.toFixed(2)).join("   ")
            color: Theme.base03
            font.pixelSize: 11
            font.family: Theme.fontMono
        }
    }
}

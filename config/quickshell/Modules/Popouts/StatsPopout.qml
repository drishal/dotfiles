pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Services

// Load at a glance: totals, every core, and what is actually eating the CPU.
// Holds a ref on Procs only while mounted, so sampling stops when it closes.
Item {
    id: root

    // Only sample while actually on screen.
    property bool live: false

    implicitWidth: 320
    implicitHeight: col.implicitHeight + 24
    width: implicitWidth
    height: implicitHeight

    onLiveChanged: {
        if (live)
            Procs.addRef();
        else
            Procs.removeRef();
    }
    Component.onDestruction: if (live)
        Procs.removeRef()

    component Meter: Column {
        id: meter

        property string label
        property string value
        property real fraction: 0
        property color fill: Theme.accent

        spacing: 4

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
            }
            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: meter.value
                font.pixelSize: 11
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
        anchors.margins: 12
        spacing: 10

        Meter {
            width: parent.width
            label: "CPU"
            value: Sys.cpu + "%"
            fraction: Sys.cpu / 100
            fill: Sys.cpu >= 85 ? Theme.base08 : Theme.base0C
        }

        // one column per thread — the shape of the load matters as much as the
        // total on a many-core box
        Row {
            width: parent.width
            height: 22
            spacing: Math.max(1, (width - Sys.cores.length * 3) / Math.max(1, Sys.cores.length - 1))

            Repeater {
                model: Sys.cores

                delegate: Item {
                    required property var modelData

                    width: 3
                    height: 22

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
            label: "Memory"
            value: Sys.memUsedGb.toFixed(1) + " / " + Sys.memTotalGb.toFixed(0) + " G"
            fraction: Sys.memPercent / 100
            fill: Sys.memPercent >= 90 ? Theme.base08 : Theme.base09
        }

        Meter {
            width: parent.width
            visible: Sys.swapTotalGb > 0
            label: "Swap"
            value: Sys.swapUsedGb.toFixed(1) + " / " + Sys.swapTotalGb.toFixed(0) + " G"
            fraction: Sys.swapPercent / 100
            fill: Theme.base0E
        }

        Item {
            width: parent.width
            height: 15

            StyledText {
                anchors.left: parent.left
                text: "load " + Sys.loadAvg.map(v => v.toFixed(2)).join("  ")
                color: Theme.inkDim
                font.pixelSize: 11
            }
            StyledText {
                anchors.right: parent.right
                text: "up " + Sys.formatUptime()
                color: Theme.inkDim
                font.pixelSize: 11
            }
        }

        StyledRect {
            width: parent.width
            height: 1
            color: Theme.base03
            opacity: 0.25
        }

        Column {
            width: parent.width
            spacing: 5

            Repeater {
                model: Procs.list.slice().sort((a, b) => b.cpu - a.cpu).slice(0, 4)

                delegate: Item {
                    required property var modelData

                    width: parent.width
                    height: 16

                    StyledText {
                        anchors.left: parent.left
                        anchors.right: pct.left
                        anchors.rightMargin: 8
                        text: modelData.name
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                    StyledText {
                        id: pct

                        anchors.right: parent.right
                        text: modelData.cpu.toFixed(1) + "%"
                        color: Theme.base0C
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }
            StyledText {
                visible: Procs.list.length === 0
                text: Procs.loading ? "Sampling…" : "No data"
                color: Theme.inkDim
                font.pixelSize: 11
            }
        }

        StyledText {
            text: "Right-click for all processes"
            color: Theme.base03
            font.pixelSize: 10
        }
    }
}

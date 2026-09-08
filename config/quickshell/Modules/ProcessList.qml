import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services

// Task manager, opened by clicking the bar's CPU/RAM cluster. Sortable table
// over Procs (instantaneous per-core CPU, not ps's lifetime average), with a
// summary strip on top and per-row terminate.

Panel {
    id: win

    name: "processes"
    keyboard: true
    slideFrom: Qt.TopEdge

    width: 780
    height: 600

    // Only sample while actually on screen.
    onShownChanged: {
        if (shown) {
            Procs.addRef();
            search.text = "";
            Procs.query = "";
            search.forceActiveFocus();
        } else {
            Procs.removeRef();
        }
    }

    component Chip: StyledRect {
        id: chip

        property string label
        property bool selected: false
        signal clicked

        implicitWidth: chipText.implicitWidth + 22
        implicitHeight: 26
        radius: 999
        color: selected ? Theme.accent : Theme.card

        StyledText {
            id: chipText

            anchors.centerIn: parent
            text: chip.label
            color: chip.selected ? Theme.accentInk : Theme.ink
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
        StateLayer {
            color: chip.selected ? Theme.accentInk : Theme.ink
            onClicked: chip.clicked()
        }
    }

    component HeaderCell: Item {
        id: hc

        property string label
        property string key
        property int align: Text.AlignLeft

        implicitHeight: 22

        StyledText {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: hc.align
            text: Procs.sortBy === hc.key ? hc.label + "  ↓" : hc.label
            color: Procs.sortBy === hc.key ? Theme.accent : Theme.inkDim
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }
        StateLayer {
            radius: 6
            onClicked: Procs.sortBy = hc.key
        }
    }

    component Meter: Column {
        id: meter

        property string label
        property string value
        property real fraction: 0
        property color fill: Theme.accent

        spacing: 4

        Item {
            width: meter.width
            height: 14

            StyledText {
                anchors.left: parent.left
                text: meter.label
                color: Theme.inkDim
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
            StyledText {
                anchors.right: parent.right
                text: meter.value
                font.pixelSize: 10
            }
        }
        StyledRect {
            width: meter.width
            height: 5
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

    Elevation {
        anchors.fill: card
        radius: card.radius
        level: 4
    }

    // The card is the container transform: it grows out of the bar's CPU/RAM
    // cluster into the full panel. The body is pinned to the panel's final
    // position (offset back by the card's travel) and clipped, so the content
    // is revealed rather than scaled — text stays crisp the whole way.
    StyledRect {
        id: card

        x: win.morphX
        y: win.morphY
        width: win.morphW
        height: win.morphH
        radius: 22
        color: Theme.base00
        border.width: 1
        border.color: Theme.base02
        clip: true

        Item {
            id: body

            x: -win.morphX
            y: -win.morphY
            width: win.width
            height: win.height
            opacity: win.contentFade

            Column {
                id: layout

                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // ── header ──
                Item {
                    id: headerRow

                    width: parent.width
                    height: 34

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        StyledIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰓠"
                            color: Theme.accent
                            font.pixelSize: 20
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Processes"
                            font.pixelSize: 17
                            font.weight: Font.Bold
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Procs.filtered.length + " of " + Procs.list.length
                            color: Theme.inkDim
                            font.pixelSize: 11
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Chip {
                            label: "All"
                            selected: Procs.scope === "all"
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: Procs.scope = "all"
                        }
                        Chip {
                            label: "Mine"
                            selected: Procs.scope === "user"
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: Procs.scope = "user"
                        }
                        Chip {
                            label: "System"
                            selected: Procs.scope === "system"
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: Procs.scope = "system"
                        }

                        StyledRect {
                            width: 30
                            height: 30
                            radius: 999
                            anchors.verticalCenter: parent.verticalCenter
                            color: "transparent"

                            StyledIcon {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.pixelSize: 16
                            }
                            StateLayer {
                                onClicked: win.close()
                            }
                        }
                    }
                }

                // ── summary strip ──
                Row {
                    id: summaryRow

                    width: parent.width
                    spacing: 14

                    readonly property real cellW: (width - spacing * 3) / 4

                    Meter {
                        width: parent.cellW
                        label: "CPU"
                        value: Sys.cpu + "%"
                        fraction: Sys.cpu / 100
                        fill: Sys.cpu >= 85 ? Theme.base08 : Theme.base0C
                    }
                    Meter {
                        width: parent.cellW
                        label: "MEMORY"
                        value: Sys.memUsedGb.toFixed(1) + " / " + Sys.memTotalGb.toFixed(0) + " G"
                        fraction: Sys.memPercent / 100
                        fill: Sys.memPercent >= 90 ? Theme.base08 : Theme.base09
                    }
                    Meter {
                        width: parent.cellW
                        label: "SWAP"
                        value: Sys.swapTotalGb > 0 ? Sys.swapUsedGb.toFixed(1) + " / " + Sys.swapTotalGb.toFixed(0) + " G" : "none"
                        fraction: Sys.swapPercent / 100
                        fill: Theme.base0E
                    }
                    Meter {
                        width: parent.cellW
                        label: "LOAD"
                        value: Sys.loadAvg[0].toFixed(2) + " · up " + Sys.formatUptime()
                        fraction: Sys.cores.length > 0 ? Sys.loadAvg[0] / Sys.cores.length : 0
                        fill: Theme.base0D
                    }
                }

                // ── search ──
                StyledRect {
                    id: searchBox

                    width: parent.width
                    height: 38
                    radius: 999
                    color: Theme.card

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        StyledIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰍉"
                        }
                        TextField {
                            id: search

                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 30
                            placeholderText: "Filter by name, command or pid…"
                            placeholderTextColor: Theme.inkDim
                            color: Theme.ink
                            font.family: Theme.fontSans
                            font.pixelSize: 13
                            background: null
                            onTextChanged: Procs.query = text
                            Keys.onEscapePressed: win.close()
                        }
                    }
                }

                // ── column headers ──
                Row {
                    id: colHeaders

                    width: parent.width
                    height: 22

                    readonly property real pidW: 70
                    readonly property real userW: 90
                    readonly property real cpuW: 80
                    readonly property real memW: 90
                    readonly property real killW: 34

                    HeaderCell {
                        width: parent.width - parent.pidW - parent.userW - parent.cpuW - parent.memW - parent.killW
                        label: "PROCESS"
                        key: "name"
                    }
                    HeaderCell {
                        width: parent.pidW
                        label: "PID"
                        key: "pid"
                    }
                    HeaderCell {
                        width: parent.userW
                        label: "USER"
                        key: "user"
                    }
                    HeaderCell {
                        width: parent.cpuW
                        label: "CPU"
                        key: "cpu"
                        align: Text.AlignRight
                    }
                    HeaderCell {
                        width: parent.memW
                        label: "MEMORY"
                        key: "mem"
                        align: Text.AlignRight
                    }
                    Item {
                        width: parent.killW
                        height: 1
                    }
                }

                // ── rows ──
                FadeFlickable {
                    id: procScroll

                    width: parent.width
                    height: layout.height - headerRow.height - summaryRow.height - searchBox.height - colHeaders.height - footerRow.height - layout.spacing * 5
                    contentHeight: rows.height

                    Column {
                        id: rows

                        width: procScroll.width
                        spacing: 2

                        Repeater {
                            model: Procs.filtered.slice(0, 300)

                            delegate: StyledRect {
                                id: prow

                                required property var modelData

                                width: rows.width
                                height: 34
                                radius: 8
                                color: "transparent"

                                readonly property real pidW: 70
                                readonly property real userW: 90
                                readonly property real cpuW: 80
                                readonly property real memW: 90
                                readonly property real killW: 34

                                StateLayer {
                                    id: rowState

                                    cursorShape: Qt.ArrowCursor
                                    acceptedButtons: Qt.NoButton
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 4
                                    anchors.rightMargin: 4

                                    Column {
                                        width: prow.width - prow.pidW - prow.userW - prow.cpuW - prow.memW - prow.killW - 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 0

                                        StyledText {
                                            width: parent.width
                                            text: prow.modelData.name
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        StyledText {
                                            width: parent.width
                                            text: prow.modelData.cmd
                                            color: Theme.base03
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                        }
                                    }
                                    StyledText {
                                        width: prow.pidW
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: prow.modelData.pid
                                        color: Theme.inkDim
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                    }
                                    StyledText {
                                        width: prow.userW
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: prow.modelData.user
                                        color: Theme.inkDim
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                    StyledText {
                                        width: prow.cpuW
                                        anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Text.AlignRight
                                        text: prow.modelData.cpu.toFixed(1) + "%"
                                        color: prow.modelData.cpu >= 50 ? Theme.base08 : Theme.base0C
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                    StyledText {
                                        width: prow.memW
                                        anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Text.AlignRight
                                        text: Procs.formatMem(prow.modelData.rssKb)
                                        color: Theme.base09
                                        font.pixelSize: 12
                                    }
                                    Item {
                                        width: prow.killW
                                        height: parent.height

                                        StyledRect {
                                            anchors.centerIn: parent
                                            width: 26
                                            height: 26
                                            radius: 999
                                            opacity: rowState.containsMouse ? 1 : 0
                                            color: "transparent"

                                            Behavior on opacity {
                                                Anim {
                                                    type: Anim.FastEffects
                                                }
                                            }

                                            StyledIcon {
                                                anchors.centerIn: parent
                                                text: "󰅖"
                                                color: killState.containsMouse ? Theme.base08 : Theme.inkDim
                                                font.pixelSize: 13
                                            }
                                            StateLayer {
                                                id: killState

                                                color: Theme.base08
                                                onClicked: Procs.kill(prow.modelData.pid)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── footer ──
                Item {
                    id: footerRow

                    width: parent.width
                    height: 22

                    StyledText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Procs.loading ? "Sampling…" : "Updated every 3s · CPU is per-core"
                        color: Theme.base03
                        font.pixelSize: 10
                    }
                    StyledText {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Procs.filtered.length > 300 ? "showing top 300" : ""
                        color: Theme.base03
                        font.pixelSize: 10
                    }
                }
            }
        }

    }
}

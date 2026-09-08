import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs.Common
import qs.Services

// The floating island. Lives inside ShellSurface as a plain Item — the window
// behind it spans the whole screen and never resizes, so nothing here has to
// fight the compositor. Hovering a status item opens the shared popout.

Item {
    id: bar

    required property string screenName
    required property var barScreen
    property Item popouts: null

    readonly property int islandInset: 4
    readonly property int islandTop: 6
    readonly property alias island: island
    readonly property string launchCmd: "rofi -show drun -icon-theme Papirus -show-icons"

    // Portrait monitors (e.g. a rotated panel) get the stats cluster collapsed
    // behind a chevron by default; landscape stays expanded.
    readonly property bool vertical: barScreen ? barScreen.height > barScreen.width : false
    property bool statsExpanded: !vertical

    // Rect of the CPU/RAM cluster in bar coordinates, for ProcessList's
    // container transform. Recomputed rather than bound: mapToItem is not a
    // tracked dependency, so the callers below poke it when the layout moves.
    property rect statsRect: Qt.rect(0, 0, 0, 0)

    function updateStatsAnchor() {
        if (!statsCell)
            return;
        const p = statsCell.mapToItem(bar, 0, 0);
        statsRect = Qt.rect(p.x, p.y, statsCell.width, statsCell.height);
    }

    onStatsExpandedChanged: Qt.callLater(updateStatsAnchor)
    Component.onCompleted: Qt.callLater(updateStatsAnchor)

    function togglePopout(item, name) {
        if (popouts)
            popouts.toggle(name, item.mapToItem(bar, item.width / 2, 0).x);
    }

    implicitHeight: 36

    // ── reusable glyph button ──────────────────────────────────────────────
    component IconButton: Item {
        id: ib

        property string glyph
        property color fg: Theme.inkDim
        property color hoverFg: Theme.accent
        property int glyphSize: 14
        property real padH: 8
        property alias hovered: ibState.containsMouse
        signal clicked

        implicitWidth: t.implicitWidth + padH * 2
        implicitHeight: 24

        StyledRect {
            anchors.fill: parent
            radius: 8
            color: "transparent"

            StyledIcon {
                id: t

                anchors.centerIn: parent
                text: ib.glyph
                color: ibState.containsMouse ? ib.hoverFg : ib.fg
                font.pixelSize: ib.glyphSize
            }
            StateLayer {
                id: ibState

                onClicked: ib.clicked()
            }
        }
    }

    // ── status cell ────────────────────────────────────────────────────────
    // Left click opens this item's popout, right click its full panel. Both are
    // deliberate: opening on hover fires constantly just from crossing the bar.
    component Cell: Item {
        id: cell

        property string popout: ""
        property string panel: ""
        property alias hovered: cellState.containsMouse
        default property alias content: inner.data
        signal clicked

        implicitWidth: inner.childrenRect.width + 16
        implicitHeight: 22

        StyledRect {
            anchors.fill: parent
            radius: 8
            color: "transparent"

            Item {
                id: inner

                anchors.centerIn: parent
                width: childrenRect.width
                height: parent.height
            }
            StateLayer {
                id: cellState

                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        if (cell.panel !== "")
                            Popups.toggle(cell.panel, bar.screenName);
                        return;
                    }
                    if (cell.popout !== "")
                        bar.togglePopout(cell, cell.popout);
                    cell.clicked();
                }
            }
        }
    }

    component Sep: StyledText {
        text: "|"
        color: Theme.base03
        font.pixelSize: 18
        leftPadding: 5
        rightPadding: 5
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    }

    // ── the floating island ────────────────────────────────────────────────
    Elevation {
        anchors.fill: island
        radius: island.radius
        level: 2
    }

    StyledRect {
        id: island

        onWidthChanged: Qt.callLater(bar.updateStatsAnchor)

        anchors.fill: parent
        anchors.leftMargin: bar.islandInset
        anchors.rightMargin: bar.islandInset
        anchors.topMargin: bar.islandTop
        radius: 16
        color: Theme.island
        border.width: 1
        border.color: Theme.base02

        // ── LEFT: launcher · workspaces · focused window ──────────────────
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: clockAnchor.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            IconButton {
                glyph: "󰀻"
                fg: Theme.base0D
                hoverFg: Theme.base0C
                glyphSize: 16
                anchors.verticalCenter: parent.verticalCenter
                onClicked: Quickshell.execDetached(["bash", "-c", bar.launchCmd])
            }

            Workspaces {
                screenName: bar.screenName
                anchors.verticalCenter: parent.verticalCenter
            }

            // Marquee rather than a hard elide — long browser titles are all
            // suffix, so eliding at a fixed width shows nothing useful.
            ScrollingText {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 10
                width: Math.min(textWidth + leftPadding, 370)
                text: ToplevelManager.activeToplevel ? (ToplevelManager.activeToplevel.title || "") : ""
                color: Theme.inkDim
            }
        }

        // ── CENTER: clock → notification center, with unread dot ───────────
        Item {
            id: clockAnchor

            anchors.centerIn: parent
            implicitWidth: clockRow.implicitWidth + 20
            height: 24

            StyledRect {
                anchors.fill: parent
                radius: 10
                color: "transparent"

                Row {
                    id: clockRow

                    anchors.centerIn: parent
                    spacing: 6

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(clock.date, "MMM d   HH:mm")
                        font.weight: Font.DemiBold
                        animate: true
                    }
                    StyledRect {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Notif.count > 0
                        width: 7
                        height: 7
                        radius: 4
                        color: Theme.base0A
                    }
                }
                StateLayer {
                    onClicked: Popups.toggle("notes", bar.screenName)
                }
            }
            SystemClock {
                id: clock

                precision: SystemClock.Minutes
            }
        }

        // ── RIGHT: battery · net · mem · cpu · tray · settings · power ─────
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9

            // battery (only if a laptop battery is present)
            Cell {
                id: batteryCell

                readonly property var dev: UPower.displayDevice
                readonly property bool present: dev && dev.isLaptopBattery && dev.ready
                readonly property bool charging: present && dev.state === UPowerDeviceState.Charging

                visible: present
                popout: "battery"
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    spacing: 6
                    height: parent.height

                    StyledIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: batteryCell.charging ? "󰂅" : "󰁹"
                        color: Theme.base0B
                        font.pixelSize: 13
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: batteryCell.present ? Math.round(batteryCell.dev.percentage * 100) + "%" : ""
                        color: Theme.base0B
                        font.pixelSize: 12
                    }
                }
            }

            // ── collapsible stats cluster: internet · ram · cpu ─────
            // Chevron collapses net/mem/cpu to declutter (default collapsed on
            // portrait monitors, expanded on landscape).
            Row {
                spacing: 9
                anchors.verticalCenter: parent.verticalCenter

                Item {
                    width: chev.implicitWidth + 10
                    height: 22
                    anchors.verticalCenter: parent.verticalCenter

                    StyledRect {
                        anchors.fill: parent
                        radius: 8
                        color: "transparent"

                        StyledIcon {
                            id: chev

                            anchors.centerIn: parent
                            // right-anchored bar grows the cluster leftward, so
                            // the chevron points left when collapsed (where
                            // content appears) and right when expanded.
                            text: "󰅁"
                            rotation: bar.statsExpanded ? 180 : 0
                            color: chevState.containsMouse ? Theme.accent : Theme.inkDim

                            Behavior on rotation {
                                Anim {
                                    type: Anim.DefaultSpatial
                                }
                            }
                        }
                        StateLayer {
                            id: chevState

                            onClicked: bar.statsExpanded = !bar.statsExpanded
                        }
                    }
                }

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 22
                    clip: true
                    visible: width > 1
                    width: bar.statsExpanded ? clusterRow.implicitWidth : 0
                    opacity: bar.statsExpanded ? 1 : 0

                    Behavior on width {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Row {
                        id: clusterRow

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 9

                        Cell {
                            popout: "network"
                            panel: "dashboard"
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                spacing: 6
                                height: parent.height

                                StyledIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Net.icon
                                    color: Theme.base0D
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Net.label
                                    color: Theme.inkDim
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    width: Math.min(implicitWidth, 130)
                                }
                            }
                        }

                        // mem + cpu share one cell: hovering shows the load
                        // popout, clicking opens the process list.
                        Cell {
                            id: statsCell

                            popout: "stats"
                            panel: "processes"
                            anchors.verticalCenter: parent.verticalCenter
                            onXChanged: bar.updateStatsAnchor()
                            onWidthChanged: bar.updateStatsAnchor()

                            Row {
                                spacing: 9
                                height: parent.height

                                Row {
                                    spacing: 6
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: ""
                                        color: Theme.base09
                                        font.pixelSize: 13
                                    }
                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Sys.memUsedGb.toFixed(1) + "G"
                                        color: Sys.memPercent >= 90 ? Theme.base08 : Theme.base09
                                        font.pixelSize: 12
                                    }
                                }
                                Row {
                                    spacing: 6
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: ""
                                        color: Theme.base0C
                                        font.pixelSize: 13
                                    }
                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Sys.cpu + "%"
                                        color: Sys.cpu >= 85 ? Theme.base08 : Theme.base0C
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Sep {
                anchors.verticalCenter: parent.verticalCenter
            }

            IconButton {
                glyph: "󰅍"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: Popups.toggle("clipboard", bar.screenName)
            }

            Sep {
                anchors.verticalCenter: parent.verticalCenter
            }

            // system tray
            Row {
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter
                visible: SystemTray.items && SystemTray.items.values.length > 0

                Repeater {
                    model: SystemTray.items ? SystemTray.items.values : []

                    delegate: Item {
                        id: trayItem

                        required property var modelData

                        width: 22
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter

                        StyledRect {
                            anchors.fill: parent
                            radius: 8
                            color: "transparent"

                            Image {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                source: trayItem.modelData.icon
                                fillMode: Image.PreserveAspectFit
                                sourceSize.width: 16
                                sourceSize.height: 16
                            }
                            StateLayer {
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu)
                                        trayMenu.open();
                                    else
                                        trayItem.modelData.activate();
                                }
                            }
                        }
                        QsMenuAnchor {
                            id: trayMenu

                            menu: trayItem.modelData.menu
                            anchor.item: trayItem
                            anchor.margins.bottom: -6
                            anchor.edges: Edges.Bottom | Edges.Left
                            anchor.gravity: Edges.Bottom | Edges.Right
                            anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
                        }
                    }
                }
            }

            Sep {
                anchors.verticalCenter: parent.verticalCenter
                visible: SystemTray.items && SystemTray.items.values.length > 0
            }

            IconButton {
                glyph: "󰘮"
                glyphSize: 15
                anchors.verticalCenter: parent.verticalCenter
                onClicked: Popups.toggle("dashboard", bar.screenName)
            }
            IconButton {
                glyph: "󰐥"
                glyphSize: 15
                hoverFg: Theme.base08
                anchors.verticalCenter: parent.verticalCenter
                onClicked: Popups.toggle("powermenu", bar.screenName)
            }
        }
    }
}

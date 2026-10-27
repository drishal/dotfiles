pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services

// Workspace overview (SUPER+TAB): this monitor's workspaces as scaled
// miniatures with live window captures. Click a window to focus it, empty
// space to switch workspace; drag a window onto another workspace — or the
// trailing "+" slot — to move it there. Captures run only while it is open.
// Window geometry comes from lastIpcObject, refreshed on open (IPC events
// do not carry it).
Panel {
    id: win

    name: "overview"
    keyboard: true

    required property var monitor

    readonly property real scaleFactor: 0.17
    readonly property real cellW: Math.round((monitor?.width ?? 1920) * scaleFactor)
    readonly property real cellH: Math.round((monitor?.height ?? 1080) * scaleFactor)
    readonly property int gap: 14
    readonly property int pad: 18

    readonly property var workspaces: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === win.monitor).sort((a, b) => a.id - b.id)
    // Next unused id, offered as a drop target for "move to a new workspace".
    readonly property int spareId: {
        const used = new Set(Hyprland.workspaces.values.map(w => w.id));
        let i = (win.workspaces.length > 0 ? win.workspaces[win.workspaces.length - 1].id : 0) + 1;
        while (used.has(i))
            i++;
        return i;
    }
    readonly property int slots: workspaces.length + 1
    readonly property int columns: Math.min(slots, 4)

    width: columns * cellW + (columns - 1) * gap + 2 * pad
    height: Math.ceil(slots / columns) * (cellH + 22 + gap) - gap + 2 * pad

    onShownChanged: if (shown)
        Hyprland.refreshToplevels()

    function focusWindow(address) {
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + address + "\" })");
        win.close();
    }
    function moveWindow(address, wsId) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + wsId + ", window = \"address:" + address + "\", follow = false })");
        Hyprland.refreshToplevels();
    }

    Grid {
        id: grid

        x: win.pad
        y: win.pad
        columns: win.columns
        spacing: win.gap

        Repeater {
            model: win.slots

            delegate: Column {
                id: cell

                required property int index
                readonly property var ws: index < win.workspaces.length ? win.workspaces[index] : null
                readonly property int wsId: ws ? ws.id : win.spareId
                readonly property bool active: ws !== null && win.monitor?.activeWorkspace === ws

                spacing: 6

                StyledText {
                    text: cell.ws ? cell.ws.name : "New workspace"
                    color: cell.active ? Theme.accent : Theme.inkDim
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                StyledRect {
                    id: frame

                    width: win.cellW
                    height: win.cellH
                    radius: 12
                    color: cell.ws ? Theme.card : "transparent"
                    border.width: drop.containsDrag || cell.active ? 2 : 1
                    border.color: drop.containsDrag ? Theme.base0B : cell.active ? Theme.accent : Theme.base02

                    StyledIcon {
                        anchors.centerIn: parent
                        visible: !cell.ws
                        text: "󰐕"
                        color: drop.containsDrag ? Theme.base0B : Theme.base03
                        font.pixelSize: 26
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: cell.ws !== null
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cell.ws.activate();
                            win.close();
                        }
                    }

                    DropArea {
                        id: drop

                        anchors.fill: parent
                        keys: ["qs-window"]
                        onDropped: drag => {
                            if (drag.source && drag.source.wsId !== cell.wsId)
                                win.moveWindow(drag.source.address, cell.wsId);
                        }
                    }

                    Repeater {
                        model: cell.ws ? cell.ws.toplevels.values : []

                        delegate: Item {
                            id: slot

                            required property var modelData
                            readonly property var ipc: modelData?.lastIpcObject ?? null
                            readonly property real s: win.scaleFactor

                            x: ipc ? Math.round((ipc.at[0] - (win.monitor?.x ?? 0)) * s) : 0
                            y: ipc ? Math.round((ipc.at[1] - (win.monitor?.y ?? 0)) * s) : 0
                            width: ipc ? Math.max(12, Math.round(ipc.size[0] * s)) : 0
                            height: ipc ? Math.max(12, Math.round(ipc.size[1] * s)) : 0
                            visible: ipc !== null && !ipc.hidden

                            ClippingRectangle {
                                id: tile

                                readonly property string address: slot.modelData?.address ?? ""
                                readonly property int wsId: cell.wsId

                                width: slot.width
                                height: slot.height
                                radius: 6
                                color: Theme.base02
                                border.width: tileMouse.containsMouse ? 2 : 0
                                border.color: Theme.accent
                                opacity: tileMouse.drag.active ? 0.85 : 1

                                Drag.active: tileMouse.drag.active
                                Drag.keys: ["qs-window"]
                                Drag.source: tile
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2

                                ScreencopyView {
                                    id: capture

                                    anchors.fill: parent
                                    captureSource: win.shown ? (slot.modelData?.wayland ?? null) : null
                                    live: win.shown
                                }
                                StyledText {
                                    anchors.centerIn: parent
                                    width: parent.width - 8
                                    horizontalAlignment: Text.AlignHCenter
                                    visible: !capture.hasContent
                                    text: slot.ipc?.class ?? ""
                                    color: Theme.inkDim
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: tileMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                    drag.target: tile
                                    onClicked: win.focusWindow(tile.address)
                                    onReleased: if (drag.active)
                                        tile.Drag.drop()
                                }

                                // Lifted out of its cell while dragged, so it can
                                // travel over the others; snaps back after.
                                states: State {
                                    when: tileMouse.drag.active

                                    ParentChange {
                                        target: tile
                                        parent: win
                                    }
                                }
                                transitions: Transition {
                                    ParentAnimation {
                                        Anim {
                                            properties: "x,y"
                                            type: Anim.FastSpatial
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

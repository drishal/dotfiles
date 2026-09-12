pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.WindowManager
import qs.Common

// Per-monitor workspace numbers. A pill sits behind the row, and the accent
// indicator marks the focused one; its leading and trailing edges animate at
// different speeds, so it stretches into a trail as it moves and settles back.
// NOTE: workspaces come from ext-workspace-v1 (Quickshell.WindowManager), not
// Quickshell.Hyprland — Hyprland 0.56 dropped workspace ids from its IPC
// (hyprwm/Hyprland#16140) and quickshell still parses them, so every workspace
// there reads back as id -1. The wheel handler still dispatches, which is a
// command rather than a query and so is unaffected; this Hyprland runs
// configType = "lua", hence the Lua expression.

Item {
    id: root

    required property string screenName

    readonly property int slotW: 26
    readonly property int slotGap: 6
    readonly property int pitch: slotW + slotGap

    readonly property var projection: {
        for (const p of WindowManager.windowsetProjections)
            if (p.screens.some(s => s && s.name === root.screenName))
                return p;
        return null;
    }

    function coordOf(ws) {
        return ws.coordinates.length > 0 ? ws.coordinates[0] : parseInt(ws.name) || 0;
    }

    // Hyprland only keeps a workspace alive while it holds windows or is
    // focused, so everything ext reports here is worth a slot.
    readonly property var slots: {
        const p = root.projection;
        if (!p)
            return [];
        return [...p.windowsets].sort((a, b) => root.coordOf(a) - root.coordOf(b));
    }

    readonly property int activeIdx: {
        for (let i = 0; i < root.slots.length; i++)
            if (root.slots[i].active)
                return i;
        return -1;
    }

    implicitWidth: Math.max(row.implicitWidth, 1)
    implicitHeight: 22

    // One pill behind the row — every slot is occupied, bar the focused one
    // when it is empty, and the accent indicator covers that anyway.
    StyledRect {
        width: Math.max(0, root.slots.length - 1) * root.pitch + root.slotW
        height: 20
        radius: 8
        visible: root.slots.length > 0
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.base01

        Behavior on width {
            Anim {
                type: Anim.Emphasized
            }
        }
    }

    // active indicator with a trailing stretch
    StyledRect {
        id: pill

        // Leading edge leads on the way there, trailing edge lags behind, so
        // the pill elongates mid-move. Equal targets, different durations.
        property real leading: Math.max(0, root.activeIdx) * root.pitch
        property real trailing: Math.max(0, root.activeIdx) * root.pitch

        visible: root.activeIdx >= 0
        x: Math.min(leading, trailing)
        width: Math.abs(leading - trailing) + root.slotW
        height: 20
        radius: 8
        color: Theme.accent
        anchors.verticalCenter: parent.verticalCenter

        Behavior on leading {
            Anim {
                type: Anim.Emphasized
                duration: Theme.animDurations[Anim.EmphasizedSmall]
            }
        }
        Behavior on trailing {
            Anim {
                type: Anim.Emphasized
                duration: Theme.animDurations[Anim.EmphasizedSmall] * 2
            }
        }
    }

    Row {
        id: row

        spacing: root.slotGap
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: ScriptModel {
                values: root.slots
            }

            delegate: StyledRect {
                id: slot

                required property var modelData

                readonly property bool active: modelData?.active ?? false
                readonly property bool isUrgent: modelData?.urgent ?? false

                width: root.slotW
                height: 20
                radius: 8
                // The pills behind paint occupied and active; only urgent needs
                // its own surface here.
                color: !active && isUrgent ? Theme.alertBg : "transparent"

                StyledText {
                    anchors.centerIn: parent
                    text: slot.modelData?.name ?? ""
                    color: {
                        if (slot.active)
                            return Theme.accentInk;
                        if (slot.isUrgent)
                            return Theme.base08;
                        if (slotState.containsMouse)
                            return Theme.ink;
                        return Theme.inkDim;
                    }
                }
                StateLayer {
                    id: slotState

                    color: slot.active ? Theme.accentInk : Theme.ink
                    onClicked: slot.modelData?.activate()
                }
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + (event.angleDelta.y < 0 ? "e+1" : "e-1") + "\" })");
        }
    }
}

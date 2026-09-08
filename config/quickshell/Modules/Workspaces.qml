import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Common

// Per-monitor workspace numbers. Two backgrounds sit under the labels: a pill
// merging each run of adjacent occupied workspaces, and the accent indicator
// for the focused one. The indicator's leading and trailing edges animate at
// different speeds, so it stretches into a trail as it moves and settles back.
// NOTE: this Hyprland runs configType = "lua", so dispatches are Lua
// expressions (hl.dsp.focus{...}), exactly like the ags config.

Item {
    id: root

    required property string screenName

    readonly property int slotW: 26
    readonly property int slotGap: 6
    readonly property int pitch: slotW + slotGap

    property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

    // Track urgent workspace ids ourselves (Hyprland exposes ws.urgent, but we
    // also clear on focus). Set of ids as a plain object.
    property var urgent: ({})

    function windowsOn(ws) {
        const o = ws.lastIpcObject;
        return o && typeof o.windows === "number" ? o.windows : (ws.toplevels ? ws.toplevels.values.length : 0);
    }
    function monitorOf(ws) {
        const o = ws.lastIpcObject;
        return o ? o.monitor : (ws.monitor ? ws.monitor.name : "");
    }

    readonly property var slots: {
        const all = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        const ids = [];
        for (const ws of all) {
            if (!ws || ws.id <= 0)
                continue;
            if (monitorOf(ws) === root.screenName && windowsOn(ws) > 0)
                ids.push(ws.id);
        }
        // Always include the focused workspace on this monitor.
        const fw = Hyprland.focusedWorkspace;
        if (fw && fw.id > 0 && monitorOf(fw) === root.screenName && ids.indexOf(fw.id) === -1)
            ids.push(fw.id);
        ids.sort((a, b) => a - b);
        return ids;
    }

    readonly property int activeIdx: root.slots.indexOf(root.focusedId)

    function isBusy(id) {
        const all = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (const ws of all)
            if (ws.id === id && monitorOf(ws) === root.screenName && windowsOn(ws) > 0)
                return true;
        return false;
    }

    // Runs of adjacent occupied slots, as [{start, end}] index pairs. One pill
    // per run reads as "these workspaces have windows" far better than N dots.
    readonly property var occupiedRuns: {
        const runs = [];
        let start = -1;
        for (let i = 0; i < root.slots.length; i++) {
            const busy = root.isBusy(root.slots[i]);
            if (busy && start < 0)
                start = i;
            if (!busy && start >= 0) {
                runs.push({
                    start: start,
                    end: i - 1
                });
                start = -1;
            }
        }
        if (start >= 0)
            runs.push({
                start: start,
                end: root.slots.length - 1
            });
        return runs;
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            // Hyprland emits `urgent` with a window address; mark its workspace.
            if (event.name === "urgent")
                Hyprland.refreshWorkspaces();
        }
    }

    // Clear urgent flag once its workspace becomes focused.
    onFocusedIdChanged: {
        if (root.urgent[root.focusedId]) {
            const n = Object.assign({}, root.urgent);
            delete n[root.focusedId];
            root.urgent = n;
        }
    }

    implicitWidth: Math.max(row.implicitWidth, 1)
    implicitHeight: 22

    // occupied-run pills (below everything)
    Repeater {
        model: root.occupiedRuns

        delegate: StyledRect {
            required property var modelData

            x: modelData.start * root.pitch
            width: (modelData.end - modelData.start) * root.pitch + root.slotW
            height: 20
            radius: 8
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.base01

            scale: 0
            Component.onCompleted: scale = 1

            Behavior on x {
                Anim {
                    type: Anim.Emphasized
                }
            }
            Behavior on width {
                Anim {
                    type: Anim.Emphasized
                }
            }
            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
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
            model: root.slots

            delegate: StyledRect {
                id: slot

                required property int modelData

                readonly property bool active: modelData === root.focusedId
                readonly property bool isUrgent: !!root.urgent[modelData]
                readonly property bool busy: root.isBusy(modelData)

                width: root.slotW
                height: 20
                radius: 8
                // The pills behind paint occupied and active; only urgent needs
                // its own surface here.
                color: !active && isUrgent ? Theme.alertBg : "transparent"

                StyledText {
                    anchors.centerIn: parent
                    text: slot.modelData
                    color: {
                        if (slot.active)
                            return Theme.accentInk;
                        if (slot.isUrgent)
                            return Theme.base08;
                        if (slotState.containsMouse)
                            return Theme.ink;
                        if (slot.busy)
                            return Theme.inkDim;
                        return Theme.base03;
                    }
                }
                StateLayer {
                    id: slotState

                    color: slot.active ? Theme.accentInk : Theme.ink
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + slot.modelData + " })")
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

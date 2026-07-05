import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Common

// Per-monitor workspace numbers with a sliding accent pill (mirrors ags
// Bar.tsx Workspaces). Shows only workspaces that have windows on THIS monitor,
// plus the focused one; the pill glides under the number labels like a tab
// indicator. NOTE: this Hyprland runs configType = "lua", so dispatches are Lua
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

    // sliding accent pill (below the labels)
    Rectangle {
        id: pill
        visible: root.activeIdx >= 0
        width: root.slotW
        height: 20
        radius: 8
        color: Theme.accent
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, root.activeIdx) * root.pitch
        Behavior on x {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }

    Row {
        id: row
        spacing: root.slotGap
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.slots
            delegate: Rectangle {
                id: slot
                required property int modelData
                readonly property bool active: modelData === root.focusedId
                readonly property bool isUrgent: !!root.urgent[modelData]
                readonly property bool busy: root.isBusy(modelData)
                width: root.slotW
                height: 20
                radius: 8
                color: {
                    if (active)
                        return "transparent"; // pill paints the bg
                    if (isUrgent)
                        return Theme.alertBg;
                    if (ma.containsMouse)
                        return Theme.base01;
                    return "transparent";
                }

                Text {
                    anchors.centerIn: parent
                    text: slot.modelData
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                    color: {
                        if (slot.active)
                            return Theme.accentInk;
                        if (slot.isUrgent)
                            return Theme.base08;
                        if (ma.containsMouse)
                            return Theme.ink;
                        if (slot.busy)
                            return Theme.inkDim;
                        return Theme.base03;
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
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

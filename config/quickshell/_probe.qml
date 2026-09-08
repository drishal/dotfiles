import QtQuick
import Quickshell
import qs.Modules
import qs.Services

ShellRoot {
    id: probe
    property var steps: ["", "clipboard", "notes", "processes", "dashboard", ""]
    property int i: 0
    Variants { model: Quickshell.screens; ShellSurface {} }
    Variants { model: Quickshell.screens; OverlaySurface {} }
    Timer {
        running: true; interval: 4000; repeat: true
        onTriggered: {
            const s = Quickshell.screens[0] ? Quickshell.screens[0].name : "";
            if (probe.i >= probe.steps.length) { console.log("PROBE DONE"); Qt.exit(0); return; }
            const n = probe.steps[probe.i++];
            if (n === "") Popups.closeAll(s); else Popups.open(n, s);
            console.log("PROBE STEP", n === "" ? "(closed)" : n);
        }
    }
}

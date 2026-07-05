pragma Singleton

// Airplane mode via rfkill (mirrors ags lib/radios.ts). A udev ACL grants the
// user rw on /dev/rfkill, so no sudo. Polls the SOFT block column every 5s;
// airplane = nothing unblocked.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool airplaneOn: false

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    Process {
        id: poll
        command: ["bash", "-c", "rfkill --output SOFT --noheadings 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.trim();
                root.airplaneOn = out ? !/\bunblocked\b/i.test(out) : false;
            }
        }
    }

    function toggle() {
        // airplaneOn is the current state — flip it.
        Quickshell.execDetached(["bash", "-c", root.airplaneOn ? "rfkill unblock all" : "rfkill block all"]);
        Qt.callLater(() => poll.running = true);
    }
}

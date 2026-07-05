pragma Singleton

// Backlight brightness via brightnessctl (mirrors ags lib/brightness.ts).
// `available` is false on machines without a backlight (desktops), so the
// dashboard can hide the slider.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property real value: 0 // 0..1

    Component.onCompleted: probe.running = true

    // detect a backlight device + read initial %
    Process {
        id: probe
        command: ["bash", "-c", "ls /sys/class/backlight 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = this.text.trim() !== "";
                if (root.available)
                    readProc.running = true;
            }
        }
    }

    Process {
        id: readProc
        command: ["bash", "-c", "brightnessctl -m i | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = Number(this.text.trim());
                if (!isNaN(n))
                    root.value = n / 100;
            }
        }
    }

    function set(v) {
        const pct = Math.max(0, Math.min(100, Math.round(v * 100)));
        root.value = pct / 100;
        Quickshell.execDetached(["brightnessctl", "s", pct + "%"]);
    }
}

pragma ComponentBehavior: Bound
pragma Singleton

// Brightness for the built-in panel (brightnessctl) and, where present, one
// external panel over DDC/CI (ddcutil). `all` holds a target per source and
// `primary` is the first, so the dashboard slider keeps working unchanged.
//
// Not yet per-monitor: the probe only establishes that at least one DDC
// display answered, and drives ddcutil's default display.
//
// ddcutil needs /dev/i2c-* access — `hardware.i2c.enable` (hosts/common/gui.nix)
// loads i2c-dev and installs the udev rules. Detect runs once at startup;
// DDC probing is slow, so it is never repeated in-session.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var all: [] // BrightnessTarget objects; rebuild() reassigns it
    readonly property bool available: all.length > 0
    readonly property var primary: all.length > 0 ? all[0] : null

    // The old single-value API the dashboard slider still uses.
    readonly property real value: primary ? primary.value : 0

    function set(v) {
        if (root.primary)
            root.primary.set(v);
    }

    Component.onCompleted: {
        probe.running = true;
        ddcProbe.running = true;
    }

    component BrightnessTarget: QtObject {
        id: target

        property string kind: "backlight" // "backlight" | "ddc"
        property string name: "" // ddc: monitor description; backlight: device
        property real value: 0 // 0..1
        readonly property bool available: kind === "backlight" || ddcReady
        property bool ddcReady: false

        function set(v) {
            const pct = Math.max(0, Math.min(100, Math.round(v * 100)));
            target.value = pct / 100;
            if (kind === "backlight")
                Quickshell.execDetached(["brightnessctl", "s", pct + "%"]);
            else
                Quickshell.execDetached(["ddcutil", "setvcp", "10", "" + pct, "--sleep-multiplier=0.02"]);
        }
    }

    // ── backlight (built-in panel) ─────────────────────────────────────────
    property BrightnessTarget backlight: null

    Process {
        id: probe
        command: ["bash", "-c", "ls /sys/class/backlight 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "")
                    return;
                const t = targetComp.createObject(root, {
                        kind: "backlight",
                        name: this.text.trim()
                    });
                root.backlight = t;
                root.rebuild();
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
                if (!isNaN(n) && root.backlight)
                    root.backlight.value = n / 100;
            }
        }
    }

    // ── ddcutil (external panels) ──────────────────────────────────────────
    property BrightnessTarget ddc: null

    Process {
        id: ddcProbe
        command: ["bash", "-c", "ddcutil detect --sleep-multiplier=0.1 2>/dev/null | grep -c 'Display 1'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (Number(this.text.trim()) >= 1) {
                    const t = targetComp.createObject(root, {
                            kind: "ddc",
                            name: "External"
                        });
                    root.ddc = t;
                    t.ddcReady = true;
                    root.rebuild();
                    ddcRead.running = true;
                }
            }
        }
    }

    Process {
        id: ddcRead
        command: ["bash", "-c", "ddcutil getvcp 10 --sleep-multiplier=0.02 2>/dev/null | grep -oE 'current value = [0-9]+' | grep -oE '[0-9]+'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = Number(this.text.trim());
                if (!isNaN(n) && root.ddc)
                    root.ddc.value = n / 100;
            }
        }
    }

    function rebuild() {
        const list = [];
        if (root.backlight)
            list.push(root.backlight);
        if (root.ddc)
            list.push(root.ddc);
        root.all = list;
    }

    Component {
        id: targetComp
        BrightnessTarget {}
    }
}

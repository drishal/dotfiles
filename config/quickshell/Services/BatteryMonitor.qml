pragma ComponentBehavior: Bound
pragma Singleton

// Battery warnings via the internal Toaster (caelestia's BatteryMonitor
// behaviour): a toast when the charge crosses each warn level downward while
// discharging. Inert on machines without a battery (the desktop) — UPower's
// DisplayDevice simply never reports ready. No automatic suspend; sleeping is
// a manual action only.

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    // Descending warn levels, critical included: never suspends, it only
    // raises the toast's severity. A drop past several at once reports the
    // most severe one crossed rather than the first.
    readonly property var warnLevels: [{
            level: 20,
            title: "Battery low",
            body: "20% remaining",
            icon: "󰁺",
            type: Toaster.Warning
        }, {
            level: 10,
            title: "Battery very low",
            body: "10% remaining — plug in",
            icon: "󰁺",
            type: Toaster.Warning
        }, {
            level: 5,
            title: "Battery critical",
            body: "5% remaining — plug in",
            icon: "󰁺",
            type: Toaster.Error
        }]

    property real lastPercent: 100
    // Lowest level already warned for this discharge; a single bool latched on
    // the first warning and made every deeper level unreachable.
    property int warnedAt: 101

    readonly property var device: UPower.displayDevice
    readonly property bool ready: device && device.ready && device.isLaptopBattery

    function check() {
        if (!root.ready || !UPower.onBattery) {
            // Re-arm while plugged in so the next discharge warns again.
            root.lastPercent = root.ready ? device.percentage * 100 : 100;
            root.warnedAt = 101;
            return;
        }
        const p = device.percentage * 100;
        if (p < root.lastPercent) {
            // Descending list, so the last match is the most severe crossed.
            let hit = null;
            for (const l of root.warnLevels)
                if (p <= l.level && root.warnedAt > l.level)
                    hit = l;
            if (hit) {
                Toaster.toast(hit.title, hit.body, hit.icon, hit.type);
                root.warnedAt = hit.level;
            }
        }
        root.lastPercent = p;
    }


    Connections {
        function onOnBatteryChanged() {
            root.check();
        }

        target: UPower
    }

    Timer {
        // Percentage changes don't always carry a signal through displayDevice
        // state transitions; a slow poll is cheap and catches drift.
        interval: 30000
        running: root.ready
        repeat: true
        onTriggered: root.check()
    }

    Component.onCompleted: check()
}

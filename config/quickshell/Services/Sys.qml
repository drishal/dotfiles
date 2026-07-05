pragma Singleton

// CPU + memory stats, derived from /proc (mirrors ags lib/system.ts).
// Polled every 3s: CPU as a 0-100 int from /proc/stat idle/total deltas,
// memory as used GiB + percent from /proc/meminfo.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpu: 0 // 0..100
    property real memUsedGb: 0
    property real memTotalGb: 0
    property int memPercent: 0

    property real _lastIdle: 0
    property real _lastTotal: 0

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            const line = statFile.text().split("\n")[0];
            if (!line.startsWith("cpu"))
                return;
            const v = line.trim().split(/\s+/).slice(1).map(Number);
            const idle = (v[3] || 0) + (v[4] || 0);
            const total = v.reduce((a, b) => a + b, 0);
            const dIdle = idle - root._lastIdle;
            const dTotal = total - root._lastTotal;
            root._lastIdle = idle;
            root._lastTotal = total;
            if (dTotal > 0)
                root.cpu = Math.min(100, Math.max(0, Math.round((1 - dIdle / dTotal) * 100)));
        }
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: {
            const info = memFile.text();
            const field = k => {
                const m = info.match(new RegExp("^" + k + ":\\s+(\\d+)", "m"));
                return m ? Number(m[1]) : 0; // kB
            };
            const total = field("MemTotal");
            const avail = field("MemAvailable");
            const used = Math.max(0, total - avail);
            root.memUsedGb = used / 1024 / 1024;
            root.memTotalGb = total / 1024 / 1024;
            root.memPercent = total ? Math.round((used / total) * 100) : 0;
        }
    }
}

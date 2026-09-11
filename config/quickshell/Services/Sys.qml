pragma ComponentBehavior: Bound
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
    property real swapUsedGb: 0
    property real swapTotalGb: 0
    property int swapPercent: 0
    // per-core 0..100, in /proc/stat order
    property var cores: []
    property var loadAvg: [0, 0, 0]
    property real uptimeSec: 0

    property real _lastIdle: 0
    property real _lastTotal: 0
    property var _lastCores: ({})

    function formatUptime() {
        const s = root.uptimeSec;
        const d = Math.floor(s / 86400);
        const h = Math.floor((s % 86400) / 3600);
        const m = Math.floor((s % 3600) / 60);
        if (d > 0)
            return d + "d " + h + "h";
        if (h > 0)
            return h + "h " + m + "m";
        return m + "m";
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            loadFile.reload();
            uptimeFile.reload();
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            const lines = statFile.text().split("\n");
            const parse = line => {
                const v = line.trim().split(/\s+/).slice(1).map(Number);
                return {
                    idle: (v[3] || 0) + (v[4] || 0),
                    total: v.reduce((a, b) => a + b, 0)
                };
            };
            const pct = (cur, prev) => {
                const dTotal = cur.total - prev.total;
                if (!(dTotal > 0))
                    return -1;
                return Math.min(100, Math.max(0, Math.round((1 - (cur.idle - prev.idle) / dTotal) * 100)));
            };

            if (!lines[0] || !lines[0].startsWith("cpu"))
                return;
            const agg = parse(lines[0]);
            const p = pct(agg, {
                idle: root._lastIdle,
                total: root._lastTotal
            });
            root._lastIdle = agg.idle;
            root._lastTotal = agg.total;
            if (p >= 0)
                root.cpu = p;

            // per-core, for the load popout's spark columns
            const next = {};
            const out = [];
            for (let i = 1; i < lines.length; i++) {
                if (!/^cpu\d/.test(lines[i]))
                    break;
                const key = lines[i].split(/\s+/)[0];
                const cur = parse(lines[i]);
                const prev = root._lastCores[key];
                out.push(prev ? Math.max(0, pct(cur, prev)) : 0);
                next[key] = cur;
            }
            root._lastCores = next;
            root.cores = out;
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

            const swapTotal = field("SwapTotal");
            const swapUsed = Math.max(0, swapTotal - field("SwapFree"));
            root.swapUsedGb = swapUsed / 1024 / 1024;
            root.swapTotalGb = swapTotal / 1024 / 1024;
            root.swapPercent = swapTotal ? Math.round((swapUsed / swapTotal) * 100) : 0;
        }
    }

    FileView {
        id: loadFile
        path: "/proc/loadavg"
        onLoaded: {
            const v = loadFile.text().trim().split(/\s+/);
            root.loadAvg = [Number(v[0]) || 0, Number(v[1]) || 0, Number(v[2]) || 0];
        }
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptimeSec = Number(uptimeFile.text().trim().split(/\s+/)[0]) || 0
    }
}

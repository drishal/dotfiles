pragma ComponentBehavior: Bound
pragma Singleton

// Process table for the task manager panel.
//
// `ps` only reports CPU averaged over a process's whole lifetime, which is
// useless for spotting what is busy *now*, so we sample /proc/<pid>/stat twice
// and diff the jiffies against the machine total — the same thing htop does.
// Percentages are per-core (a saturated thread reads 100%, not 100/ncpu).
//
// Polling only runs while a panel holds a ref, so an idle shell costs nothing.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // [{ pid, cpu, rssKb, user, cmd, name }]
    property var list: []
    property bool loading: false
    property string query: ""
    property string sortBy: "cpu" // cpu | mem | name | pid
    property string scope: "all"  // all | user | system
    property string user: Quickshell.env("USER") || ""

    property int refs: 0

    function addRef() {
        refs += 1;
        if (refs === 1)
            refresh();
    }
    function removeRef() {
        refs = Math.max(0, refs - 1);
        // ~900 objects and their command lines; no reason to hold them while
        // nothing is displaying them.
        if (refs === 0)
            list = [];
    }

    function refresh() {
        if (sampler.running)
            return;
        loading = true;
        sampler.running = true;
    }

    function kill(pid, signal) {
        Quickshell.execDetached(["kill", "-" + (signal || "TERM"), "" + pid]);
        Qt.callLater(() => root.refresh());
    }

    function formatMem(kb) {
        if (kb < 1024)
            return kb.toFixed(0) + " K";
        if (kb < 1024 * 1024)
            return (kb / 1024).toFixed(0) + " M";
        return (kb / 1024 / 1024).toFixed(1) + " G";
    }

    readonly property var filtered: {
        let out = root.list.slice();

        if (root.scope === "user")
            out = out.filter(p => p.user === root.user);
        else if (root.scope === "system")
            out = out.filter(p => p.user !== root.user);

        const q = root.query.trim().toLowerCase();
        if (q.length > 0)
            out = out.filter(p => p.name.toLowerCase().includes(q) || p.cmd.toLowerCase().includes(q) || ("" + p.pid).includes(q));

        const by = root.sortBy;
        out.sort((a, b) => {
            if (by === "mem")
                return b.rssKb - a.rssKb;
            if (by === "pid")
                return a.pid - b.pid;
            if (by === "name")
                return a.name.localeCompare(b.name);
            return b.cpu - a.cpu;
        });
        return out;
    }

    readonly property real totalCpu: root.list.reduce((a, p) => a + p.cpu, 0)
    readonly property real totalRssGb: root.list.reduce((a, p) => a + p.rssKb, 0) / 1024 / 1024

    Timer {
        interval: 3000
        running: root.refs > 0
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: sampler

        command: ["bash", "-c", `
d="\${XDG_RUNTIME_DIR:-/tmp}/quickshell-procs"
mkdir -p "$d"
jiffies() { awk '/^cpu /{s=0;for(i=2;i<=NF;i++)s+=$i;print s;exit}' /proc/stat; }
# utime+stime live after the last ") " — a comm containing spaces or parens
# would shift plain field indices.
snap() { awk '{n=split($0,a,") ");split(a[n],f," ");print $1" "f[12]+f[13]}' /proc/[0-9]*/stat 2>/dev/null; }
t1=$(jiffies); snap > "$d/a"
sleep 0.4
t2=$(jiffies); snap > "$d/b"
ps -eo pid=,user=,rss=,args= 2>/dev/null > "$d/p"
dt=$((t2-t1)); [ "$dt" -le 0 ] && dt=1
awk -v dt="$dt" -v nc="$(nproc)" '
  FILENAME ~ /a$/ { a[$1]=$2; next }
  FILENAME ~ /b$/ { b[$1]=$2; next }
  {
    pid=$1; usr=$2; rss=$3;
    $1=""; $2=""; $3=""; sub(/^ +/, "");
    d = b[pid] - a[pid]; if (d < 0 || b[pid] == "") d = 0;
    printf "%s\\t%.1f\\t%s\\t%s\\t%s\\n", pid, d*100*nc/dt, rss, usr, $0;
  }' "$d/a" "$d/b" "$d/p"
`]

        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of this.text.split("\n")) {
                    const f = line.split("\t");
                    if (f.length < 5)
                        continue;
                    const cmd = f[4];
                    if (cmd === "")
                        continue;
                    // First token's basename reads better than a store path.
                    const first = cmd.split(" ")[0];
                    const name = first.split("/").pop() || first;
                    out.push({
                        pid: parseInt(f[0]) || 0,
                        cpu: parseFloat(f[1]) || 0,
                        rssKb: parseInt(f[2]) || 0,
                        user: f[3],
                        // qemu-style command lines run to kilobytes; nothing in
                        // the UI shows more than a line of it.
                        cmd: cmd.length > 220 ? cmd.slice(0, 220) + "…" : cmd,
                        name: name
                    });
                }
                root.list = out;
                root.loading = false;
            }
        }
    }
}

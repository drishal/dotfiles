pragma Singleton

// cliphist-backed clipboard history (mirrors ags lib/clipboard.ts).
//
// `cliphist list` emits `<id>\t<preview>` per line; image entries carry a
// synthetic preview like `[[ binary data 178 KiB png 876x781 ]]` which we
// decode to small cached thumbnails so the popup stays light. Copying
// re-decodes to the clipboard with the right MIME type; deletes feed the raw
// line to `cliphist delete` over stdin (via an env var, never the shell) so
// arbitrary payloads can't be interpreted.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string thumbDir: "/tmp/qs-clip-thumbs-v1"
    readonly property int maxRows: 100

    property var entries: [] // capped list of {id, raw, preview, isImage, ...}
    property int total: 0
    property string query: ""

    readonly property var filtered: {
        const q = root.query.trim().toLowerCase();
        if (!q)
            return root.entries;
        return root.entries.filter(e => e.preview.toLowerCase().indexOf(q) !== -1);
    }
    readonly property int count: root.total

    readonly property var imgRe: /^\[\[ (?:binary data|image) (.+?) (jpe?g|png|bmp|webp|gif) (\d+x\d+) \]\]/

    function parse(out) {
        const res = [];
        for (const line of out.split("\n")) {
            const tab = line.indexOf("\t");
            if (tab < 0)
                continue;
            const id = line.slice(0, tab);
            const preview = line.slice(tab + 1);
            const m = preview.match(root.imgRe);
            if (m) {
                const ext = m[2] === "jpeg" ? "jpg" : m[2];
                res.push({
                    id: id,
                    raw: line,
                    preview: preview,
                    isImage: true,
                    sizeText: m[1],
                    imageType: m[2],
                    dimensions: m[3],
                    thumb: root.thumbDir + "/" + id + "-" + ext + ".png"
                });
            } else {
                res.push({
                    id: id,
                    raw: line,
                    preview: preview,
                    isImage: false,
                    imageType: "",
                    sizeText: "",
                    dimensions: "",
                    thumb: ""
                });
            }
        }
        return res;
    }

    function refresh() {
        listProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const all = root.parse(this.text);
                root.total = all.length;
                root.entries = all.slice(0, root.maxRows);
                // decode any missing image thumbnails, then re-publish so the
                // Image sources pick up the freshly written files.
                Quickshell.execDetached(["bash", "-c", "mkdir -p '" + root.thumbDir + "'; " + root.entries.filter(e => e.isImage).map(e => "[ -f '" + e.thumb + "' ] || cliphist decode " + e.id + " | magick - -thumbnail 160x160 '" + e.thumb + "'").join("; ")]);
                thumbTimer.restart();
            }
        }
    }

    Timer {
        id: thumbTimer
        interval: 700
        onTriggered: root.entries = root.entries.slice() // new refs → reload thumbs
    }

    function copy(e) {
        if (e.isImage) {
            const mime = (e.imageType === "jpg" || e.imageType === "jpeg") ? "image/jpeg" : "image/" + e.imageType;
            Quickshell.execDetached(["bash", "-c", "cliphist decode " + e.id + " | wl-copy --type " + mime]);
        } else {
            Quickshell.execDetached(["bash", "-c", "cliphist decode " + e.id + " | wl-copy"]);
        }
    }

    Process {
        id: delProc
        stdout: StdioCollector {
            onStreamFinished: root.refresh()
        }
    }

    function remove(e) {
        // Pass the raw entry via env (never the shell) so payloads with
        // quotes/newlines/$() can't be interpreted.
        delProc.running = false;
        delProc.environment = ({
                "RAW": e.raw
            });
        delProc.command = ["bash", "-c", "printf '%s' \"$RAW\" | cliphist delete"];
        delProc.running = true;
    }

    function wipe() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        Qt.callLater(root.refresh);
    }
}

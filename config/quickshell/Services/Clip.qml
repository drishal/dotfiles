pragma ComponentBehavior: Bound
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
                const missing = root.entries.filter(e => e.isImage).map(e => "[ -f '" + e.thumb + "' ] || cliphist decode " + e.id + " | magick - -thumbnail 160x160 '" + e.thumb + "'");
                if (missing.length > 0) {
                    thumbProc.command = ["bash", "-c", "mkdir -p '" + root.thumbDir + "'; " + missing.join("; ")];
                    thumbProc.running = true;
                }
            }
        }
    }

    // Re-publish once the decodes have actually finished, so the Image sources
    // pick up the new files — a fixed delay left slow decodes blank.
    Process {
        id: thumbProc
        onExited: root.entries = root.entries.slice()
    }

    // ── expanded view: full content of one entry ──────────────────────────
    readonly property string fullDir: "/tmp/qs-clip-full-v1"
    readonly property int textCap: 20000

    property bool expanded: false
    property var detail: null // entry being previewed
    property string detailText: ""
    property bool detailTruncated: false
    property string detailImage: "" // decoded full-size file, set once ready
    property bool detailBusy: false

    function select(e) {
        textProc.running = false;
        imgProc.running = false;
        root.detail = e;
        root.detailText = "";
        root.detailTruncated = false;
        root.detailImage = "";
        root.detailBusy = false;
        if (!e)
            return;
        root.detailBusy = true;
        if (e.isImage) {
            const ext = e.imageType === "jpeg" ? "jpg" : e.imageType;
            imgProc.target = root.fullDir + "/" + e.id + "." + ext;
            imgProc.command = ["bash", "-c", "mkdir -p \"$2\"; [ -f \"$3\" ] || { cliphist decode \"$1\" > \"$3.tmp\" && mv \"$3.tmp\" \"$3\"; }", "_", e.id, root.fullDir, imgProc.target];
            imgProc.running = true;
        } else {
            // Bytes, not chars: leaves headroom so the char cap is what trips.
            textProc.command = ["bash", "-c", "cliphist decode \"$1\" | head -c " + root.textCap * 2, "_", e.id];
            textProc.running = true;
        }
    }

    // Drops the preview and the decoded full-size files.
    function clearDetail() {
        root.select(null);
        Quickshell.execDetached(["rm", "-rf", root.fullDir]);
    }

    Process {
        id: textProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.detail || root.detail.isImage)
                    return;
                root.detailTruncated = this.text.length > root.textCap;
                root.detailText = this.text.slice(0, root.textCap);
                root.detailBusy = false;
            }
        }
    }

    Process {
        id: imgProc
        property string target: ""
        onExited: code => {
            if (code !== 0 || !root.detail || imgProc.target.indexOf("/" + root.detail.id + ".") < 0)
                return;
            root.detailImage = imgProc.target;
            root.detailBusy = false;
        }
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

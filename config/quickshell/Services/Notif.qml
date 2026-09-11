pragma ComponentBehavior: Bound
pragma Singleton

// Notification server + state (mirrors ags AstalNotifd usage across
// NotificationCenter / NotificationPopups / the clock unread dot / DND tile).
//
// `list`  — all tracked notifications, newest first (the center).
// `popups`— transient stack that auto-hides after 5s (critical never hides).
//
// The center survives `qs kill; qs`: live notifications are snapshotted to
// XDG_STATE/quickshell/notifs.json (1s debounce) and reloaded as plain
// snapshot objects (live object methods are gone, so actions become no-ops).
// DND survives hot reloads via PersistentProperties.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Hyprland

Singleton {
    id: root

    // Aliased through PersistentProperties below, so DND survives hot reloads.
    property bool dnd: false
    property var list: [] // [{ n, time }], newest first, capped at maxList
    // Uncapped, this grows for the whole session and every entry pins a
    // notification object and its image.
    readonly property int maxList: 100
    property var popups: [] // [{ n, time }]
    // False until the state file has been folded in, so the restore itself
    // never triggers a save.
    property bool loaded: false

    readonly property int count: list.length

    // Any monitor showing a real fullscreen window (2 = fullscreen on that
    // monitor in Hyprland's client JSON).
    function hasFullscreen() {
        const ms = Hyprland.monitors ? Hyprland.monitors.values : [];
        for (const m of ms) {
            const tl = m.activeWorkspace ? m.activeWorkspace.toplevels : null;
            if (tl && tl.values.some(t => t.lastIpcObject && t.lastIpcObject.fullscreen > 1))
                return true;
        }
        return false;
    }

    function visibleActions(n) {
        const out = [];
        for (const a of (n.actions || []))
            if (a.identifier !== "default" && (a.text || "").trim() !== "")
                out.push(a);
        return out;
    }

    function _removeFrom(arr, n) {
        return arr.filter(e => e.n !== n);
    }

    function dismiss(n) {
        try {
            n.dismiss();
        } catch (e) {}
    }
    function clearAll() {
        const snapshot = root.list.slice();
        for (const e of snapshot)
            root.dismiss(e.n);
    }
    function toggleDnd() {
        root.dnd = !root.dnd;
    }

    function _drop(n) {
        root.list = root._removeFrom(root.list, n);
        root.popups = root._removeFrom(root.popups, n);
    }

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;
            const entry = {
                n: notif,
                time: Date.now()
            };

            // center: replace if already present (same object on update), else prepend
            root.list = [entry].concat(root._removeFrom(root.list, notif)).slice(0, root.maxList);

            // Popups yield to fullscreen apps (they still land in the center);
            // critical breaks through so battery warnings reach a fullscreen game.
            const critical = notif.urgency === NotificationUrgency.Critical;
            if (!root.dnd && (critical || !root.hasFullscreen())) {
                root.popups = [entry].concat(root._removeFrom(root.popups, notif));
                if (!critical)
                    hideTimer.createObject(root, {
                        notif: notif
                    });
            }
        }
    }

    // Per-notification lifecycle: prune when dismissed/expired anywhere.
    Instantiator {
        model: root.list
        delegate: QtObject {
            required property var modelData
            Component.onCompleted: {
                // Live notifications expose Retainable; restored snapshots
                // don't (dropped already means gone for them).
                const n = modelData && modelData.n;
                if (n && n.Retainable && n.Retainable.dropped)
                    n.Retainable.dropped.connect(() => root._drop(modelData.n));
            }
        }
    }

    // Transient popup auto-hide timers (only removes from the popup stack; the
    // notification stays in the center until dismissed).
    Component {
        id: hideTimer
        Timer {
            property var notif
            interval: 5000
            running: true
            onTriggered: {
                root.popups = root._removeFrom(root.popups, notif);
                destroy();
            }
        }
    }

    // ── persistence ────────────────────────────────────────────────────────
    Component {
        id: snapshotComp
        QtObject {
            property string summary: ""
            property string body: ""
            property string appName: ""
            property string appIcon: ""
            property string image: ""
            property int urgency: 1 // NotificationUrgency.Normal
            property var actions: []
            // Server-side tracking is gone for restored notifications, so
            // dismissal just drops them from the local list.
            function dismiss() {
                root._drop(this);
            }
        }
    }

    // Plain data URI images can be huge (screenshot bodies); beyond ~100k they
    // are not worth their JSON footprint.
    function _clipped(s, cap) {
        s = s || "";
        return s.length > cap ? "" : s;
    }

    function _serialize() {
        return JSON.stringify(root.list.map(e => ({
                    time: e.time,
                    summary: (e.n.summary || "").slice(0, 4000),
                    body: (e.n.body || "").slice(0, 4000),
                    appName: e.n.appName || "",
                    appIcon: root._clipped(e.n.appIcon, 100000),
                    image: root._clipped(e.n.image, 100000),
                    urgency: e.n.urgency === undefined ? 1 : e.n.urgency,
                    actions: (e.n.actions || []).filter(a => a.identifier !== "default" && (a.text || "").trim() !== "").map(a => ({
                                identifier: a.identifier || "",
                                text: a.text || ""
                            }))
                })));
    }

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: storage.setText(root._serialize())
    }

    onListChanged: {
        if (root.loaded)
            saveTimer.restart();
    }

    FileView {
        id: storage
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell/notifs.json"
        printErrors: false
        onLoaded: {
            let data = [];
            try {
                data = JSON.parse(text()) || [];
            } catch (e) {
                data = [];
            }
            const restored = data.filter(d => d && typeof d === "object").map(d => {
                const acts = (d.actions || []).map(a => ({
                            identifier: a.identifier || "",
                            text: a.text || "",
                            // Restored actions cannot reach the original server.
                            invoke: function () {}
                        }));
                return {
                    n: snapshotComp.createObject(root, {
                            summary: d.summary || "",
                            body: d.body || "",
                            appName: d.appName || "",
                            appIcon: d.appIcon || "",
                            image: d.image || "",
                            urgency: d.urgency === undefined ? 1 : d.urgency,
                            actions: acts
                        }),
                    time: d.time || 0
                };
            });
            restored.sort((a, b) => b.time - a.time);
            root.list = restored.concat(root.list).slice(0, root.maxList);
            root.loaded = true;
        }
        onLoadFailed: err => {
            root.loaded = true;
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => storage.setText("[]"));
        }
    }

    // DND flips on hot reload otherwise. Aliasing (not a copy) means the
    // persisted value flows in when reload restores state and root writes
    // propagate back — no completion-order race.
    PersistentProperties {
        id: notifProps

        reloadableId: "notifs"

        property bool dnd: false

        onDndChanged: root.dnd = notifProps.dnd
    }

    Binding {
        target: notifProps
        property: "dnd"
        value: root.dnd
    }
}

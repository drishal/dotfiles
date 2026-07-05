pragma Singleton

// Notification server + state (mirrors ags AstalNotifd usage across
// NotificationCenter / NotificationPopups / the clock unread dot / DND tile).
//
// `list`  — all tracked notifications, newest first (the center).
// `popups`— transient stack that auto-hides after 5s (critical never hides).

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property var list: [] // [{ n, time }]
    property var popups: [] // [{ n, time }]

    readonly property int count: list.length

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
            root.list = [entry].concat(root._removeFrom(root.list, notif));

            if (!root.dnd) {
                root.popups = [entry].concat(root._removeFrom(root.popups, notif));
                if (notif.urgency !== NotificationUrgency.Critical)
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
                if (modelData.n && modelData.n.Retainable)
                    modelData.n.Retainable.dropped.connect(() => root._drop(modelData.n));
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
}

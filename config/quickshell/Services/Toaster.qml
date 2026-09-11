pragma ComponentBehavior: Bound
pragma Singleton

// Internal toast stack — shell-own events (DND flipped, game mode, battery,
// idle, now playing) shown without touching the notifd pipeline. Pure QML,
// mirroring caelestia's Toaster: severity levels, auto-expiry, and fullscreen
// suppression for non-critical toasts.
//
// Toast objects are plain QtObjects with a `closed` flag, so Toasts.qml can
// animate them out before they leave the stack.

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    enum Type {
        Normal,
        Warning,
        Error
    }

    property var list: [] // Toast objects, newest first
    readonly property int count: list.length

    // Same fullscreen check as Notif — non-critical toasts yield to games.
    function hasFullscreen() {
        const ms = Hyprland.monitors ? Hyprland.monitors.values : [];
        for (const m of ms) {
            const tl = m.activeWorkspace ? m.activeWorkspace.toplevels : null;
            if (tl && tl.values.some(t => t.lastIpcObject && t.lastIpcObject.fullscreen > 1))
                return true;
        }
        return false;
    }

    function toast(summary, body, icon, type) {
        const critical = type === Toaster.Error;
        if (!critical && root.hasFullscreen())
            return;
        const t = toastComp.createObject(root, {
                summary: summary || "",
                body: body || "",
                icon: icon || "",
                type: type || Toaster.Normal
            });
        root.list = [t].concat(root.list);
        // Cap the stack so a misbehaving caller cannot flood the overlay.
        if (root.list.length > 5)
            root.list = root.list.slice(0, 5);
        expireTimer.createObject(root, {
                toast: t
            });
    }

    function close(t) {
        root.list = root.list.filter(x => x !== t);
        t.destroy();
    }

    Component {
        id: toastComp
        QtObject {
            property string summary: ""
            property string body: ""
            property string icon: ""
            property int type: 0
            property real time: Date.now()
        }
    }

    Component {
        id: expireTimer
        Timer {
            property var toast
            interval: toast && toast.type === Toaster.Error ? 8000 : 5000
            running: true
            onTriggered: {
                root.close(toast);
                destroy();
            }
        }
    }
}

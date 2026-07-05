pragma Singleton

// Per-monitor popup state (mirrors ags lib/windows.ts). At most one of the
// exclusive popups is open per screen at a time; opening one closes the others
// on the same monitor. Bar buttons and the popups themselves live in the same
// quickshell process, so this shared singleton replaces the ags per-monitor
// window toggling — no IPC needed.

import QtQuick
import Quickshell

Singleton {
    id: root

    // The exclusive group. Transient surfaces (volume OSD, notification
    // popups) are not tracked here.
    readonly property var group: ["dashboard", "notes", "powermenu", "clipboard"]

    // screenName -> currently open popup name ("" = none). Reassigned wholesale
    // on every change so bindings referencing openByScreen re-evaluate.
    property var openByScreen: ({})

    function current(screenName) {
        return root.openByScreen[screenName] || "";
    }
    function isOpen(name, screenName) {
        return root.current(screenName) === name;
    }
    function _set(screenName, name) {
        const next = Object.assign({}, root.openByScreen);
        next[screenName] = name;
        root.openByScreen = next;
    }
    function open(name, screenName) {
        root._set(screenName, name);
    }
    function close(name, screenName) {
        if (root.current(screenName) === name)
            root._set(screenName, "");
    }
    function closeAll(screenName) {
        root._set(screenName, "");
    }
    function toggle(name, screenName) {
        root._set(screenName, root.current(screenName) === name ? "" : name);
    }
}

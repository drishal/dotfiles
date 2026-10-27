pragma ComponentBehavior: Bound
pragma Singleton

// Fullscreen detection over Hyprland IPC. The fullscreen event only flips
// `workspace.hasFullscreen`, which is also true for a maximized window, and
// leaves every toplevel's `lastIpcObject.fullscreen` stale — so each flip
// re-fetches the toplevels, and real fullscreen is `fullscreen > 1` on those.

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property string fsKey: Hyprland.workspaces.values.filter(w => w.hasFullscreen).map(w => w.id).join(",")
    onFsKeyChanged: Hyprland.refreshToplevels()

    function isFullscreen(ws) {
        return !!ws && ws.hasFullscreen && ws.toplevels.values.some(t => (t.lastIpcObject?.fullscreen ?? 0) > 1);
    }

    function monitorFullscreen(monitor) {
        return root.isFullscreen(monitor?.activeWorkspace ?? null);
    }

    function anyFullscreen() {
        return Hyprland.monitors.values.some(m => root.monitorFullscreen(m));
    }
}

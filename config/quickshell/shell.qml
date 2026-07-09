//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Modules
import qs.Services

ShellRoot {
    id: root

    // Hot-reload QML edits (the config dir is a live symlink to the repo), so
    // edits apply without relaunching — mirrors the ags `ags quit; ags run`
    // live-edit workflow but automatic.
    Component.onCompleted: Quickshell.watchFiles = true

    // Toggle popups from outside (keybinds / CLI), scoped to the focused
    // monitor:  qs ipc call popups toggle dashboard
    IpcHandler {
        target: "popups"
        function focusedScreen(): string {
            return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        }
        function toggle(name: string): void {
            Popups.toggle(name, focusedScreen());
        }
        function open(name: string): void {
            Popups.open(name, focusedScreen());
        }
        function close(name: string): void {
            Popups.close(name, focusedScreen());
        }
    }

    // One instance of each surface per monitor (Variants injects modelData =
    // the screen). Bar is always-on; the popups toggle via the Popups
    // singleton, scoped per monitor.
    Variants {
        model: Quickshell.screens
        Bar {}
    }
    Variants {
        model: Quickshell.screens
        Dashboard {}
    }
    Variants {
        model: Quickshell.screens
        NotificationCenter {}
    }
    Variants {
        model: Quickshell.screens
        PowerMenu {}
    }
    Variants {
        model: Quickshell.screens
        Clipboard {}
    }
    Variants {
        model: Quickshell.screens
        NotificationPopups {}
    }
    Variants {
        model: Quickshell.screens
        VolumePopup {}
    }
}

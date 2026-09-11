pragma ComponentBehavior: Bound
//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Modules
import qs.Services

ShellRoot {
    id: root

    // Hot-reload QML edits (the config dir is a live symlink to the repo), so
    // edits apply without relaunching.
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

    // qs ipc call lock lock — `loginctl lock-session` also works, LockState
    // listens for the logind signal.
    IpcHandler {
        target: "lock"

        function lock(): void {
            LockState.lock();
        }
        function unlock(): void {
            LockState.unlock();
        }
        function isLocked(): bool {
            return LockState.locked;
        }
    }

    // qs ipc call toast show "Title" "Body" — also the smoke-test path for
    // the internal toast stack.
    IpcHandler {
        target: "toast"

        function show(summary: string, body: string): void {
            Toaster.toast(summary, body, "", Toaster.Normal);
        }
    }

    LockScreen {}

    // Three windows per monitor, all fixed at screen size: a zero-input strut
    // reserving the bar's space, the Top-layer surface holding the bar and
    // every interactive panel, and the Overlay-layer surface for transient
    // feedback that must survive a fullscreen window.
    Variants {
        model: Quickshell.screens

        BarExclusion {}
    }
    Variants {
        model: Quickshell.screens

        ShellSurface {}
    }
    Variants {
        model: Quickshell.screens

        OverlaySurface {}
    }
}

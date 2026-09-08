pragma Singleton

// Lock screen state, shared so the IPC handler, the logind Lock signal and the
// surfaces themselves all drive one source of truth. The password buffer lives
// here too, so typing works no matter which monitor's surface has focus.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    enum Status {
        Idle,
        Authenticating,
        Failed,
        Error,
        MaxTries
    }

    property bool locked: false
    property string buffer: ""
    property int status: LockState.Idle
    property string message: ""

    // The lock is useless — and a lockout — without its PAM stack, which only
    // exists after `security.pam.services.quickshell` is switched in. Until
    // then, hand off to swaylock rather than trapping the session.
    property bool pamReady: false
    readonly property var fallbackCmd: ["swaylock", "--screenshots", "--clock", "--indicator", "--effect-blur", "7x5", "--effect-vignette", "0.5:0.5", "--fade-in", "0.2"]

    signal shake
    // Raised by a surface on Enter; LockScreen owns the PamContext.
    signal submit

    function lock() {
        if (locked)
            return;
        if (!pamReady) {
            Quickshell.execDetached(root.fallbackCmd);
            return;
        }
        buffer = "";
        status = LockState.Idle;
        message = "";
        locked = true;
    }

    function unlock() {
        locked = false;
        buffer = "";
        status = LockState.Idle;
    }

    FileView {
        path: "/etc/pam.d/quickshell"
        printErrors: false // absent until the NixOS switch; that is the signal
        onLoaded: root.pamReady = true
        onLoadFailed: root.pamReady = false
    }

    // `loginctl lock-session` — which the power menu, the dashboard and any
    // idle daemon already call — only emits a D-Bus signal; something has to
    // listen for it, or those buttons would do nothing once hyprlock is gone.
    Process {
        running: true
        command: ["dbus-monitor", "--system", "type='signal',interface='org.freedesktop.login1.Session',member='Lock'", "type='signal',interface='org.freedesktop.login1.Session',member='Unlock'"]

        stdout: SplitParser {
            onRead: data => {
                if (data.includes("member=Lock"))
                    root.lock();
                else if (data.includes("member=Unlock"))
                    root.unlock();
            }
        }
    }
}

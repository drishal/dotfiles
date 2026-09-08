import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.Services

// Session lock, replacing swaylock/hyprlock. The compositor holds the session
// closed until `unlock()`, so nothing here can be bypassed by killing a window.
//
// Authentication goes through PAM (`security.pam.services.quickshell` on the
// NixOS side). Every monitor gets a surface; the focused one takes keys, and
// all of them share one buffer so typing lands wherever you look.

Scope {
    id: root

    WlSessionLock {
        id: lock

        locked: LockState.locked

        surface: WlSessionLockSurface {
            id: lockSurface

            color: "transparent"

            LockSurface {
                anchors.fill: parent
                screen: lockSurface.screen
            }
        }
    }

    Connections {
        target: LockState

        function onSubmit() {
            pam.start();
        }
    }

    PamContext {
        id: pam

        config: "quickshell"

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(LockState.buffer);
        }

        onCompleted: result => {
            LockState.buffer = "";

            if (result === PamResult.Success) {
                LockState.unlock();
                return;
            }

            if (result === PamResult.MaxTries) {
                LockState.status = LockState.MaxTries;
                LockState.message = "Too many attempts";
            } else if (result === PamResult.Error) {
                LockState.status = LockState.Error;
                LockState.message = "Authentication error";
            } else {
                LockState.status = LockState.Failed;
                LockState.message = "Incorrect password";
            }
            LockState.shake();
            resetTimer.restart();
        }

        onError: err => {
            LockState.status = LockState.Error;
            LockState.message = "PAM error — is security.pam.services.quickshell set?";
            LockState.shake();
        }
    }

    Timer {
        id: resetTimer

        interval: 3500
        onTriggered: {
            if (LockState.status !== LockState.MaxTries) {
                LockState.status = LockState.Idle;
                LockState.message = "";
            }
        }
    }
}

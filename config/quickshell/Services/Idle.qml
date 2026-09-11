pragma ComponentBehavior: Bound
pragma Singleton

// Session idle management (caelestia's IdleMonitors, condensed): after
// `timeout` seconds without input, lock the session — nothing else. No DPMS
// and no automatic suspend anywhere; the screen going dark and sleeping are
// manual actions only. Inhibited while any Mpris player is playing, and the
// session always locks before system sleep (logind PrepareForSleep).
//
// There is no hypridle on this setup — this replaces it. Respect the
// compositor's own inhibitors (a video playing fullscreen holds one).

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Services

Singleton {
    id: root

    readonly property int timeout: 600 // seconds of idle before lock
    // Music playing should not lock the screen mid-album; players with
    // mpris-based inhibitors hold their own, this covers the ones that don't.
    readonly property bool audioPlaying: {
        const ps = Mpris.players ? Mpris.players.values : [];
        for (const p of ps)
            if (p.playbackState === MprisPlaybackState.Playing)
                return true;
        return false;
    }

    function lockSession() {
        LockState.lock();
    }

    IdleMonitor {
        enabled: !root.audioPlaying
        timeout: root.timeout * 1000
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                root.lockSession();
        }
    }

    // Lock before system sleep (systemctl suspend / power menu path).
    Process {
        running: true
        command: ["dbus-monitor", "--system", "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]

        stdout: SplitParser {
            onRead: data => {
                if (data.includes("boolean true"))
                    root.lockSession();
            }
        }
    }
}

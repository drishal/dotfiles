pragma Singleton

// Active *physical* audio output (mirrors ags lib/audio.ts).
//
// The system default sink is the EasyEffects virtual sink, whose volume is
// inaudible — EE pushes processed audio to a physical device whose level is
// what you actually hear (and what the media keys drive, via scripts/vol.sh).
// We can't tell which physical sink EE feeds, so we watch every physical
// speaker and treat whichever one changes as the active output — that follows
// Spark → aux → speakers switching for free.

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property PwNode activeNode: null
    readonly property real volume: activeNode && activeNode.audio ? activeNode.audio.volume : 0
    readonly property int percent: Math.round(volume * 100)
    readonly property bool muted: activeNode && activeNode.audio ? activeNode.audio.muted : false

    // Bumped on every real volume/mute change of the active output — drives the
    // volume OSD show trigger. Suppressed until the initial bindings settle so
    // there's no startup flash.
    property int changePulse: 0
    property bool _ready: false

    function isEE(n) {
        const s = ((n.name || "") + " " + (n.description || "")).toLowerCase();
        return s.indexOf("easyeffects") !== -1 || s.indexOf("easy effects") !== -1;
    }

    readonly property var sinks: {
        const out = [];
        if (Pipewire.nodes)
            for (const n of Pipewire.nodes.values)
                if (n && n.isSink && !n.isStream && !isEE(n))
                    out.push(n);
        return out;
    }

    // Default microphone (for the dashboard mic tile).
    readonly property PwNode source: Pipewire.defaultAudioSource

    function nodeChanged(n) {
        root.activeNode = n;
        if (root._ready)
            root.changePulse++;
    }

    function setVolume(v) {
        if (activeNode && activeNode.audio)
            activeNode.audio.volume = Math.max(0, Math.min(1, v));
    }
    function toggleMute() {
        if (activeNode && activeNode.audio)
            activeNode.audio.muted = !activeNode.audio.muted;
    }

    onSinksChanged: {
        if (!activeNode && sinks.length > 0) {
            const def = Pipewire.defaultAudioSink;
            activeNode = (def && sinks.indexOf(def) !== -1) ? def : sinks[0];
        }
    }

    // Bind audio data for every physical sink + the mic so volume/mute update.
    PwObjectTracker {
        objects: {
            const o = root.sinks.slice();
            if (root.source)
                o.push(root.source);
            return o;
        }
    }

    // Per-node change detection: whichever speaker moves becomes active.
    Instantiator {
        model: root.sinks
        delegate: QtObject {
            required property var modelData
            readonly property real v: modelData.audio ? modelData.audio.volume : 0
            readonly property bool m: modelData.audio ? modelData.audio.muted : false
            onVChanged: root.nodeChanged(modelData)
            onMChanged: root.nodeChanged(modelData)
        }
    }

    Timer {
        interval: 800
        running: true
        onTriggered: root._ready = true
    }
}

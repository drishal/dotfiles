pragma ComponentBehavior: Bound
pragma Singleton

// Audio spectrum from cava's raw ascii output (one `v;v;…;` frame per line,
// 0–100). Ref-counted like Procs: cava only runs while something displaying
// it is on screen, so an idle shell never captures audio.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int bars: 24
    property var values: []
    property int refs: 0

    function addRef() {
        refs += 1;
    }
    function removeRef() {
        refs = Math.max(0, refs - 1);
        if (refs === 0)
            values = [];
    }

    readonly property string config: ["[general]", "bars = " + bars, "framerate = 60", "[input]", "method = pipewire", "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii", "ascii_max_range = 100", "bar_delimiter = 59", "frame_delimiter = 10", "[smoothing]", "noise_reduction = 70"].join("\\n")

    Process {
        running: root.refs > 0
        // cava wants a config path; process substitution hands it one
        // without a temp file.
        command: ["bash", "-c", "exec cava -p <(printf '" + root.config + "\\n')"]
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(";");
                v.pop();
                root.values = v.map(Number);
            }
        }
    }
}

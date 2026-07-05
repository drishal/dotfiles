pragma Singleton

// Network readout via nmcli (mirrors ags lib/network.ts, which keyed off
// NetworkManager's primary connection). Shows the wired interface name when
// ethernet is primary, the SSID on wifi, else the radio state.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string icon: "󰤭"
    property string label: "…"
    property bool active: false

    function refresh() {
        proc.running = true;
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: proc
        command: ["bash", "-c", "dev=$(nmcli -t -f TYPE,STATE,CONNECTION,DEVICE device 2>/dev/null); wifi=$(nmcli -t radio wifi 2>/dev/null); printf '%s\\n---\\n%s' \"$dev\" \"$wifi\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("\n---\n");
                const dev = (parts[0] || "").split("\n");
                const wifiEnabled = (parts[1] || "").trim() === "enabled";

                let eth = null, wifi = null;
                for (const line of dev) {
                    const f = line.split(":");
                    if (f.length < 2 || f[1] !== "connected")
                        continue;
                    if (f[0] === "ethernet" && !eth)
                        eth = { conn: f[2], iface: f[3] };
                    else if (f[0] === "wifi" && !wifi)
                        wifi = { ssid: f[2], iface: f[3] };
                }

                if (eth) {
                    root.icon = "󰈁"; // ethernet
                    root.label = eth.iface || "Wired";
                    root.active = true;
                } else if (wifi) {
                    root.icon = ""; // wifi
                    root.label = wifi.ssid || "Wi-Fi";
                    root.active = true;
                } else {
                    root.icon = wifiEnabled ? "󰤭" : "󰖪";
                    root.label = wifiEnabled ? "Disconnected" : "Off";
                    root.active = false;
                }
            }
        }
    }
}

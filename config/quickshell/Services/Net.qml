pragma Singleton

// Network readout + wifi control via nmcli (mirrors ags lib/network.ts, which
// keyed off NetworkManager's primary connection). Shows the wired interface
// name when ethernet is primary, the SSID on wifi, else the radio state.
//
// Also backs the dashboard's expandable wifi panel (DMS-style): scan results,
// saved profiles, connect/disconnect/forget. Rescanning only runs while a panel
// holds a ref (addRef/removeRef), so idle cost stays one nmcli poll.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string icon: "󰤭"
    property string label: "…"
    property bool active: false

    property bool wifiEnabled: false
    property bool wifiPresent: false
    property string ssid: ""
    // [{ ssid, signal, secured, saved, active }] — active first, then strongest
    property var networks: []
    property bool scanning: false
    property string busySsid: ""
    property string error: ""

    property int refs: 0

    function addRef() {
        refs += 1;
        if (refs === 1)
            scan(true);
    }

    function removeRef() {
        refs = Math.max(0, refs - 1);
    }

    function refresh() {
        proc.running = true;
    }

    // nmcli -t escapes ':' inside values as '\:' — split on the unescaped ones.
    function splitFields(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) {
                cur += line[++i];
            } else if (c === ":") {
                out.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        out.push(cur);
        return out;
    }

    function scan(rescan) {
        if (list.running)
            return;
        scanning = true;
        list.command = ["bash", "-c", (rescan ? "nmcli device wifi rescan 2>/dev/null; " : "") + "nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list 2>/dev/null; echo '---'; nmcli -t -f TYPE,NAME connection show 2>/dev/null"];
        list.running = true;
    }

    function connect(ssid, password) {
        error = "";
        busySsid = ssid;
        conn.command = password ? ["nmcli", "device", "wifi", "connect", ssid, "password", password] : ["nmcli", "connection", "up", "id", ssid];
        conn.running = true;
    }

    function disconnect(ssid) {
        busySsid = ssid;
        conn.command = ["nmcli", "connection", "down", "id", ssid];
        conn.running = true;
    }

    function forget(ssid) {
        busySsid = ssid;
        conn.command = ["nmcli", "connection", "delete", "id", ssid];
        conn.running = true;
    }

    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]);
        Qt.callLater(() => root.refresh());
    }

    function signalIcon(strength) {
        if (strength >= 75)
            return "󰤨";
        if (strength >= 50)
            return "󰤥";
        if (strength >= 25)
            return "󰤢";
        return "󰤟";
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Rescan while a panel is open; nmcli caches results, so this is cheap.
    Timer {
        interval: 15000
        running: root.refs > 0
        repeat: true
        onTriggered: root.scan(true)
    }

    Process {
        id: proc
        command: ["bash", "-c", "dev=$(nmcli -t -f TYPE,STATE,CONNECTION,DEVICE device 2>/dev/null); wifi=$(nmcli -t radio wifi 2>/dev/null); printf '%s\\n---\\n%s' \"$dev\" \"$wifi\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("\n---\n");
                const dev = (parts[0] || "").split("\n");
                const wifiEnabled = (parts[1] || "").trim() === "enabled";

                let eth = null, wifi = null, hasWifi = false;
                for (const line of dev) {
                    const f = root.splitFields(line);
                    if (f.length < 2)
                        continue;
                    if (f[0] === "wifi")
                        hasWifi = true;
                    if (f[1] !== "connected")
                        continue;
                    if (f[0] === "ethernet" && !eth)
                        eth = { conn: f[2], iface: f[3] };
                    else if (f[0] === "wifi" && !wifi)
                        wifi = { ssid: f[2], iface: f[3] };
                }

                root.wifiEnabled = wifiEnabled;
                root.wifiPresent = hasWifi;
                root.ssid = wifi ? (wifi.ssid || "") : "";

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

    Process {
        id: list
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("\n---\n");

                const saved = {};
                for (const line of (parts[1] || "").split("\n")) {
                    const f = root.splitFields(line);
                    if (f[0] === "802-11-wireless" && f[1])
                        saved[f[1]] = true;
                }

                const seen = {};
                const out = [];
                for (const line of (parts[0] || "").split("\n")) {
                    const f = root.splitFields(line);
                    if (f.length < 4)
                        continue;
                    const ssid = f.slice(3).join(":");
                    if (!ssid || seen[ssid])
                        continue;
                    seen[ssid] = true;
                    const sec = (f[2] || "").trim();
                    out.push({
                        ssid: ssid,
                        signal: parseInt(f[1]) || 0,
                        secured: sec !== "" && sec !== "--",
                        saved: !!saved[ssid],
                        active: f[0] === "*"
                    });
                }
                out.sort((a, b) => (b.active - a.active) || (b.signal - a.signal));

                root.networks = out;
                root.scanning = false;
            }
        }
    }

    Process {
        id: conn
        stderr: StdioCollector {
            onStreamFinished: {
                const e = this.text.trim();
                root.error = e ? e.replace(/^Error:\s*/, "") : "";
            }
        }
        onExited: {
            root.busySsid = "";
            root.refresh();
            root.scan();
        }
    }
}

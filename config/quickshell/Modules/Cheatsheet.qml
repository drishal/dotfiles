pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services

// Keybind cheatsheet (SUPER+/), read live from `hyprctl binds -j` each time
// it opens. Under the Lua config IPC only reports dispatcher names, so the
// text comes from each bind's `description` (set by hyprland.nix's `bind`
// helper); undescribed binds are counted, not listed. Binds sharing a
// description (workspaces 1–0) collapse into one row.
Panel {
    id: win

    name: "cheatsheet"
    keyboard: true

    width: 960
    height: layout.implicitHeight + 40

    property var rows: []
    property int hidden: 0

    readonly property var categories: [
        {
            title: "Apps",
            icon: "󰀻",
            match: /terminal|launcher|browser|file manager|emacs|task manager|mixer|emoji|clipboard/i
        },
        {
            title: "Windows",
            icon: "󰖲",
            match: /window|floating|fullscreen|swap|layout/i
        },
        {
            title: "Workspaces",
            icon: "󰕰",
            match: /workspace/i
        },
        {
            title: "System",
            icon: "󰒓",
            match: /.*/
        }
    ]

    onShownChanged: if (shown)
        binds.running = true

    function mods(mask) {
        const out = [];
        if (mask & 64)
            out.push("Super");
        if (mask & 4)
            out.push("Ctrl");
        if (mask & 8)
            out.push("Alt");
        if (mask & 1)
            out.push("Shift");
        return out;
    }
    function keyName(k) {
        const named = {
            RETURN: "Enter",
            SPACE: "Space",
            TAB: "Tab",
            period: ".",
            slash: "/",
            mouse_down: "Scroll ↓",
            mouse_up: "Scroll ↑",
            "mouse:272": "LMB",
            "mouse:273": "RMB",
            XF86AudioRaiseVolume: "Vol +",
            XF86AudioLowerVolume: "Vol −",
            XF86AudioMute: "Mute"
        };
        return named[k] ?? (k.length === 1 ? k.toUpperCase() : k);
    }

    function build(json) {
        let list = [];
        try {
            list = JSON.parse(json);
        } catch (e) {
            return;
        }
        const byDesc = new Map();
        let hidden = 0;
        for (const b of list) {
            if (!b.description) {
                hidden++;
                continue;
            }
            const m = win.mods(b.modmask).join("+");
            const row = byDesc.get(b.description) ?? {
                desc: b.description,
                mods: win.mods(b.modmask),
                modKey: m,
                keys: []
            };
            // A second chord for the same action only shares a row when the
            // modifiers match, so "Super+1…0" stays readable.
            if (row.modKey === m)
                row.keys.push(win.keyName(b.key));
            byDesc.set(b.description, row);
        }
        const rows = [];
        for (const r of byDesc.values()) {
            const keys = r.keys.length > 3 ? [r.keys[0] + " … " + r.keys[r.keys.length - 1]] : r.keys;
            rows.push({
                desc: r.desc,
                chips: r.mods.concat([keys.join(" / ")])
            });
        }
        win.rows = rows;
        win.hidden = hidden;
    }

    function rowsFor(i) {
        const cats = win.categories;
        return win.rows.filter(r => {
            for (let c = 0; c < cats.length; c++)
                if (cats[c].match.test(r.desc))
                    return c === i;
            return false;
        });
    }

    Process {
        id: binds

        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: win.build(this.text)
        }
    }

    component Chip: StyledRect {
        id: chip

        property alias text: chipText.text

        width: chipText.implicitWidth + 14
        height: 22
        radius: 7
        color: Theme.base02

        StyledText {
            id: chipText

            anchors.centerIn: parent
            color: Theme.ink
            font.family: Theme.fontMono
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }

    Column {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 16

        Item {
            width: parent.width
            height: 28

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                StyledIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰌌"
                    color: Theme.accent
                    font.pixelSize: 20
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Keybinds"
                    color: Theme.base07
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }
            }
            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: win.hidden > 0
                text: win.hidden + " binds without a description"
                color: Theme.inkDim
                font.pixelSize: 11
            }
        }

        Row {
            width: parent.width
            spacing: 16

            Repeater {
                model: win.categories.length

                delegate: Column {
                    id: col

                    required property int index
                    readonly property var cat: win.categories[index]
                    readonly property var items: win.rowsFor(index)

                    width: (layout.width - 16 * (win.categories.length - 1)) / win.categories.length
                    spacing: 8

                    Row {
                        spacing: 8

                        StyledIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: col.cat.icon
                            color: Theme.accent
                            font.pixelSize: 15
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: col.cat.title
                            color: Theme.accent
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }

                    Repeater {
                        model: col.items

                        delegate: Column {
                            id: row

                            required property var modelData

                            width: col.width
                            spacing: 4

                            StyledText {
                                width: parent.width
                                text: row.modelData.desc
                                color: Theme.ink
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            Flow {
                                width: parent.width
                                spacing: 4

                                Repeater {
                                    model: row.modelData.chips

                                    delegate: Chip {
                                        required property string modelData

                                        text: modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

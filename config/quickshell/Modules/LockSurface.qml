import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.Common
import qs.Modules.Lock
import qs.Services

// Visuals for the session lock. Split out from LockScreen so it can be
// instantiated (and so type-checked) without actually locking the session.
//
// Three columns: ambient info left, auth centre, system state right. The side
// columns only render on the focused monitor — duplicating a notification list
// across every screen is noise, and the auth column is what matters everywhere.
Item {
    id: surface

    // The lock surface this fills; used only to tell which monitor is focused.
    property var screen: null

    readonly property string screenName: screen ? screen.name : ""
    readonly property bool primary: !screen || !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === screenName

    // Below this the three columns stop fitting side by side.
    readonly property bool wide: width >= 1280 && height >= 760

    // ── blurred wallpaper ──
    Image {
        id: wall

        anchors.fill: parent
        source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
        sourceSize.width: surface.width
        sourceSize.height: surface.height
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        blurEnabled: true
        blur: 1
        blurMax: 48
        saturation: -0.2
    }
    // Sits under the wallpaper when it fails to load, over it otherwise.
    Rectangle {
        anchors.fill: parent
        color: Theme.base00
        opacity: wall.status === Image.Ready ? 0.55 : 1
    }

    // ── columns ──
    // Anchored rather than packed in a Row: the centre column stays centred on
    // the screen whether or not the side columns are showing.
    Item {
        id: columns

        anchors.fill: parent
        anchors.margins: Math.round(Math.min(72, surface.width * 0.05))

        readonly property bool sides: surface.wide && surface.primary
        readonly property int gap: 28

        Center {
            id: centre

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 380
        }

        Column {
            anchors.left: parent.left
            anchors.right: centre.left
            anchors.rightMargin: columns.gap
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            visible: columns.sides
            spacing: 14

            WeatherCard {
                width: parent.width
            }
            FetchCard {
                width: parent.width
            }
            MediaCard {
                width: parent.width
            }
        }

        Column {
            anchors.left: centre.right
            anchors.leftMargin: columns.gap
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            visible: columns.sides
            spacing: 14

            ResourcesCard {
                width: parent.width
            }
            NotifDock {
                width: parent.width
                height: Math.max(160, parent.height - y)
            }
        }
    }

    // ── status strip ──
    // Kept for the narrow/secondary case, where the side columns are hidden and
    // this is the only ambient readout.
    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 28
        visible: !surface.wide || !surface.primary
        spacing: 18

        Row {
            spacing: 8

            StyledIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: Net.icon
                color: Theme.base0D
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Net.label
                color: Theme.base06
                font.pixelSize: 12
            }
        }

        Row {
            readonly property var dev: UPower.displayDevice
            readonly property bool present: dev && dev.isLaptopBattery && dev.ready

            spacing: 8
            visible: present

            StyledIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰁹"
                color: Theme.base0B
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.present ? Math.round(parent.dev.percentage * 100) + "%" : ""
                color: Theme.base06
                font.pixelSize: 12
            }
        }
    }

    // Keys go to whichever surface the compositor focused; the buffer is
    // shared, so it does not matter which one that is.
    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (LockState.status === LockState.Authenticating)
                return;
            if (LockState.status === LockState.MaxTries)
                return;

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                LockState.status = LockState.Authenticating;
                LockState.message = "";
                LockState.submit();
            } else if (event.key === Qt.Key_Backspace) {
                LockState.buffer = event.modifiers & Qt.ControlModifier ? "" : LockState.buffer.slice(0, -1);
            } else if (event.key === Qt.Key_Escape) {
                LockState.buffer = "";
            } else if (/^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
                LockState.buffer += event.text;
            }
            event.accepted = true;
        }
    }
}

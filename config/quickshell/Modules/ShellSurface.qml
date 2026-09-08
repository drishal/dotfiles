import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Common
import qs.Modules.Popouts
import qs.Services

// One layer-shell surface per monitor, covering the whole output, hosting the
// bar and every interactive panel.
//
// This is the point of the whole arrangement: the surface is created once at
// screen size and never resized, so a panel growing or sliding is ordinary
// scene-graph work rather than a layer-shell reconfigure per frame (which is
// what made animated panels stutter when each one owned its own window). Input
// is confined to what is actually drawn by `mask`, so the rest of the output
// stays click-through. Updating that region is a cheap commit — unlike a
// resize, it needs no buffer reallocation or round-trip.

PanelWindow {
    id: win

    required property var modelData

    readonly property string screenName: win.screen ? win.screen.name : ""
    readonly property bool anyPanel: Popups.current(screenName) !== ""

    screen: modelData
    color: "transparent"

    WlrLayershell.namespace: "quickshell-shell"
    WlrLayershell.layer: WlrLayer.Top
    // The bar's strut is reserved by a separate zero-size window, so this one
    // must not also claim space.
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: anyPanel ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    mask: Region {
        // Explicit rather than `item: bar.island`, so the bar's clickability
        // does not depend on how nested-item geometry is mapped.
        Region {
            x: bar.islandInset
            y: bar.islandTop
            width: bar.width - bar.islandInset * 2
            height: bar.height - bar.islandTop
        }
        Region {
            x: popouts.maskX
            y: popouts.maskY
            width: popouts.maskW
            height: popouts.maskH
        }
        PanelRegion {
            panel: dashboard
        }
        PanelRegion {
            panel: notes
        }
        PanelRegion {
            panel: clipboard
        }
        PanelRegion {
            panel: powermenu
        }
        PanelRegion {
            panel: processes
        }
    }

    // A hidden panel must contribute nothing, or its reserved rect would
    // swallow clicks meant for the window underneath.
    component PanelRegion: Region {
        required property Item panel

        x: panel.x
        y: panel.y
        width: panel.visible ? panel.width : 0
        height: panel.visible ? panel.height : 0
    }

    // Click anywhere outside an open panel to dismiss it — with every panel in
    // one window this is a single grab instead of one per popup.
    HyprlandFocusGrab {
        active: win.anyPanel
        windows: [win]
        onCleared: Popups.closeAll(win.screenName)
    }

    Bar {
        id: bar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        screenName: win.screenName
        barScreen: win.screen
        popouts: popouts
    }

    PopoutHost {
        id: popouts

        anchors.fill: parent
        screenName: win.screenName
    }

    Dashboard {
        id: dashboard

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 42
        anchors.rightMargin: 8

        screenName: win.screenName
    }

    NotificationCenter {
        id: notes

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 42

        screenName: win.screenName
    }

    Clipboard {
        id: clipboard

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 42
        anchors.rightMargin: 8

        screenName: win.screenName
    }

    PowerMenu {
        id: powermenu

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 42

        screenName: win.screenName
    }

    // Grows out of the bar's CPU/RAM cluster rather than appearing under the
    // clock, so the panel visibly belongs to the thing that opened it.
    ProcessList {
        id: processes

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 42
        anchors.rightMargin: 8

        screenName: win.screenName
        morphFrom: Qt.rect(bar.statsRect.x - processes.x, bar.statsRect.y - processes.y, bar.statsRect.width, bar.statsRect.height)
    }
}

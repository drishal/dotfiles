pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services

// Second per-monitor surface, on the overlay layer so transient feedback still
// shows over a fullscreen window — which the bar deliberately must not. Same
// fixed-size, masked arrangement as ShellSurface.

PanelWindow {
    id: win

    required property var modelData

    readonly property string screenName: win.screen ? win.screen.name : ""

    screen: modelData
    color: "transparent"

    WlrLayershell.namespace: "quickshell-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    // Screen corners are decoration only and stay out of the mask, so they
    // never eat a click.
    mask: Region {
        PanelRegion {
            panel: notifications
        }
        PanelRegion {
            panel: volume
        }
        PanelRegion {
            panel: toasts
        }
    }
    Toasts {
        id: toasts

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.bottomMargin: 12

        screenName: win.screenName
    }

    component PanelRegion: Region {
        required property Item panel

        x: panel.x
        y: panel.y
        width: panel.visible ? panel.width : 0
        height: panel.visible ? panel.height : 0
    }

    ScreenCorners {}

    NotificationPopups {
        id: notifications

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 42

        screenName: win.screenName
    }

    VolumePopup {
        id: volume

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 64

        screenName: win.screenName
    }
}

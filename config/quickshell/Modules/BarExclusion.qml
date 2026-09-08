import QtQuick
import Quickshell
import Quickshell.Wayland

// Zero-input strut for the bar. ShellSurface covers the whole output and so
// cannot reserve space itself; this reserves the bar's height and nothing else.
PanelWindow {
    required property var modelData

    screen: modelData
    color: "transparent"

    WlrLayershell.namespace: "quickshell-strut"
    anchors.top: true
    implicitHeight: 36
    exclusiveZone: 36
    mask: Region {}
}

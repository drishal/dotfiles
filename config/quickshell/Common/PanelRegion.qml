pragma ComponentBehavior: Bound
import Quickshell

// Input region for one panel. A hidden panel must contribute nothing, or its
// reserved rect would swallow clicks meant for the window underneath.
Region {
    required property var panel

    x: panel.x
    y: panel.y
    width: panel.visible ? panel.width : 0
    height: panel.visible ? panel.height : 0
}

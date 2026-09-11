pragma ComponentBehavior: Bound
import QtQuick

// Rectangle that cross-fades every colour change. Used shell-wide so Stylix
// switches and hover tints animate without a Behavior at each call site.
Rectangle {
    color: "transparent"

    Behavior on color {
        CAnim {}
    }
    Behavior on border.color {
        CAnim {}
    }
}

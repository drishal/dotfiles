import QtQuick
import QtQuick.Effects
import qs.Common

// Rounds off the physical screen corners, so panels and fullscreen windows sit
// in a softened frame instead of hard 90° edges. Decoration only — these stay
// out of the surface mask, so they never eat a click.
Item {
    id: root

    property int size: 14
    property color fill: "black"

    anchors.fill: parent

    // A filled square with a disc punched out of its inner corner.
    component Corner: Item {
        id: corner

        property int cx: 0 // 0 = left, 1 = right
        property int cy: 0 // 0 = top,  1 = bottom

        width: root.size
        height: root.size
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskInverted: true
            maskSource: discMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.4 // soften the cut so the arc is not stair-stepped

            Item {
                id: discMask

                anchors.fill: parent
                layer.enabled: true
                visible: false

                // Radius-`size` circle centred on the corner's inner vertex.
                Rectangle {
                    x: corner.cx === 0 ? 0 : -root.size
                    y: corner.cy === 0 ? 0 : -root.size
                    width: root.size * 2
                    height: root.size * 2
                    radius: root.size
                    color: "white"
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: root.fill
        }
    }

    Corner {
        anchors.top: parent.top
        anchors.left: parent.left
        cx: 0
        cy: 0
    }
    Corner {
        anchors.top: parent.top
        anchors.right: parent.right
        cx: 1
        cy: 0
    }
    Corner {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        cx: 0
        cy: 1
    }
    Corner {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        cx: 1
        cy: 1
    }
}

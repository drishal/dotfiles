pragma ComponentBehavior: Bound
import QtQuick
import qs.Common

// Material 3 Expressive loading indicator: a filled shape that springs from
// one polygon-ish outline to the next while it turns. Stops (and costs
// nothing) when `running` is false.
Item {
    id: root

    property bool running: true
    property color color: Theme.accent

    // (lobes, amplitude) pairs — soft burst, clover, pill, pentagon, flower,
    // cookie — in the order M3's indicator cycles through similar shapes.
    readonly property var shapes: [[7, 0.14], [4, 0.2], [2, 0.16], [5, 0.12], [8, 0.1], [9, 0.07]]
    property int step: 0

    implicitWidth: 24
    implicitHeight: 24
    visible: running

    PolarShape {
        id: shape

        anchors.fill: parent
        fillColor: root.color
        segments: 96
        lobes: root.shapes[root.step % root.shapes.length][0]
        amplitude: root.shapes[root.step % root.shapes.length][1]
        lobes2: root.shapes[(root.step + 1) % root.shapes.length][0]
        amplitude2: root.shapes[(root.step + 1) % root.shapes.length][1]

        RotationAnimator on rotation {
            running: root.running && root.visible
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 2600
        }
    }

    SequentialAnimation {
        running: root.running && root.visible
        loops: Animation.Infinite

        PauseAnimation {
            duration: 180
        }
        Anim {
            target: shape
            property: "morph"
            from: 0
            to: 1
            type: Anim.FastSpatial
            duration: 420
        }
        ScriptAction {
            script: {
                root.step = (root.step + 1) % root.shapes.length;
                shape.morph = 0;
            }
        }
    }
}

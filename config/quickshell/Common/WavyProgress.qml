pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs.Common

// Material 3 Expressive wavy progress: the played part is a sine wave that
// flows while `playing` and flattens out when paused; the rest is a flat
// track. The wave is built once one wavelength longer than the bar and only
// translated to flow, so a playing bar costs no geometry rebuilds — those
// happen only while the amplitude eases in or out. Emits `seek` on click.
Item {
    id: root

    property real value: 0
    property bool playing: false
    property bool seekable: false
    property color color: Theme.accent
    property color trackColor: Theme.base02
    property real thickness: 3
    property real wavelength: 28
    property real waveHeight: 3

    signal seek(real fraction)

    readonly property real amplitude: playing ? waveHeight : 0
    property real amp: amplitude
    property real phase: 0
    readonly property real mid: height / 2
    property real split: Math.round(Math.max(0, Math.min(1, value)) * width)
    readonly property real gap: 6

    implicitHeight: 16

    Behavior on amp {
        Anim {
            type: Anim.DefaultEffects
        }
    }
    Behavior on split {
        Anim {
            type: Anim.StandardSmall
        }
    }

    NumberAnimation on phase {
        running: root.playing && root.visible
        loops: Animation.Infinite
        from: 0
        to: 1
        duration: 1400
    }

    Rectangle {
        x: Math.min(root.width, root.split + root.gap)
        y: root.mid - height / 2
        width: Math.max(0, root.width - x)
        height: root.thickness
        radius: height / 2
        color: root.trackColor
    }

    Item {
        width: root.split
        height: root.height
        clip: true

        Shape {
            x: -(1 - root.phase) * root.wavelength
            width: root.width + root.wavelength
            height: root.height
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: root.color
                strokeWidth: root.thickness
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathPolyline {
                    path: {
                        const pts = [];
                        const len = root.width + root.wavelength;
                        const k = 2 * Math.PI / root.wavelength;
                        for (let x = 0; x <= len; x += 2)
                            pts.push(Qt.point(x, root.mid + root.amp * Math.sin(k * x)));
                        return pts;
                    }
                }
            }
        }
    }

    // M3's stop handle at the playhead.
    Rectangle {
        x: root.split - width / 2
        y: root.mid - height / 2
        width: 4
        height: root.thickness + 2 * root.waveHeight + 4
        radius: 2
        color: root.color
        visible: root.value > 0
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.seekable
        cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: event => root.seek(Math.max(0, Math.min(1, event.x / width)))
    }
}

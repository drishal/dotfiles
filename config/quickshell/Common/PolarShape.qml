pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs.Common

// Material 3 Expressive cookie / burst outline as a polar curve,
// r(θ) = 1 + amplitude·cos(lobes·θ), scaled to fit the item. `morph` blends
// towards a second (lobes2, amplitude2) curve for shape-shifting indicators.
// Geometry rebuilds only when those inputs change — spin it with `rotation`.
Shape {
    id: root

    property int lobes: 9
    property real amplitude: 0.06
    property int lobes2: lobes
    property real amplitude2: amplitude
    property real morph: 0
    property color fillColor: Theme.accent
    property color strokeColor: "transparent"
    property real strokeWidth: 0
    property int segments: 144

    readonly property var points: {
        const cx = width / 2;
        const cy = height / 2;
        const R = (Math.min(width, height) - strokeWidth) / 2 / (1 + Math.max(amplitude, amplitude2));
        const pts = [];
        for (let i = 0; i <= segments; i++) {
            const t = i / segments * Math.PI * 2;
            const r1 = 1 + amplitude * Math.cos(lobes * t);
            const r2 = 1 + amplitude2 * Math.cos(lobes2 * t);
            const r = R * (r1 + (r2 - r1) * morph);
            pts.push(Qt.point(cx + r * Math.sin(t), cy - r * Math.cos(t)));
        }
        return pts;
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fillColor
        strokeColor: root.strokeWidth > 0 ? root.strokeColor : "transparent"
        strokeWidth: root.strokeWidth > 0 ? root.strokeWidth : -1
        joinStyle: ShapePath.RoundJoin

        PathPolyline {
            path: root.points
        }
    }
}

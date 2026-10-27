pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Common

// Every surface of the shell surface painted as one layer: the bar island plus
// each attached panel, joined to it by concave fillets. Drawing them together
// lets one shadow and one opacity apply to the union, so the seams between
// island and drawer never show as a double shadow or a darker overlap.
//
// `surfaces` lists attached panels (and the popout host); each exposes its
// surface as surfaceX/Y/W/H relative to its own x/y, plus `radius`. Fillets shrink as a surface nears the
// island's ends, where they would run into its rounded corners; inside the
// corner the island's own bottom radius gives way instead, so a drawer flush
// with the edge reads as one L-shaped piece.
Item {
    id: root

    required property real islandX
    required property real islandW
    property var surfaces: []

    readonly property real islandL: islandX
    readonly property real islandR: islandX + islandW
    readonly property real ir: Theme.islandRadius

    // Gap between a surface edge and the island end, grown while the surface
    // is still shallow so the corner eases back as the drawer retracts.
    function gapL(s) {
        return s.x + s.surfaceX - islandL + Math.max(0, ir - s.surfaceH);
    }
    function gapR(s) {
        return islandR - (s.x + s.surfaceX + s.surfaceW) + Math.max(0, ir - s.surfaceH);
    }

    readonly property real cornerL: {
        let r = ir;
        for (const s of surfaces)
            if (s.visible && s.surfaceH > 0.5)
                r = Math.min(r, Math.max(0, gapL(s)));
        return r;
    }
    readonly property real cornerR: {
        let r = ir;
        for (const s of surfaces)
            if (s.visible && s.surfaceH > 0.5)
                r = Math.min(r, Math.max(0, gapR(s)));
        return r;
    }

    opacity: Theme.surfaceAlpha
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.6)
        shadowBlur: 0.7
        blurMax: 24
        shadowVerticalOffset: 3
    }

    StyledRect {
        x: root.islandX
        y: Theme.islandTop
        width: root.islandW
        height: Theme.barHeight - Theme.islandTop
        radius: root.ir
        bottomLeftRadius: root.cornerL
        bottomRightRadius: root.cornerR
        color: Theme.island
    }

    Repeater {
        model: root.surfaces

        delegate: Drawer {
            required property var modelData

            sx: modelData.x + modelData.surfaceX
            sy: modelData.y + modelData.surfaceY
            sw: modelData.surfaceW
            sh: modelData.visible ? modelData.surfaceH : 0
            br: modelData.radius
            fl: Math.min(Theme.filletRadius, Math.max(0, root.gapL(modelData) - root.ir))
            fr: Math.min(Theme.filletRadius, Math.max(0, root.gapR(modelData) - root.ir))
        }
    }

    // A surface with square top corners, rounded bottom ones, and a concave
    // fillet flaring into the island on each side.
    component Drawer: Shape {
        id: d

        property real sx
        property real sy
        property real sw
        property real sh
        property real br
        property real fl
        property real fr

        // Radii keep a hair above zero so a drawer flush with the edge (no
        // fillet) never feeds a degenerate arc to the renderer.
        readonly property real b: Math.max(0.01, Math.min(br, sw / 2, sh / 2))
        readonly property real l: Math.max(0.01, Math.min(fl, sh - b))
        readonly property real r: Math.max(0.01, Math.min(fr, sh - b))

        visible: sh > 0.5 && sw > 0.5
        x: sx - l
        y: sy
        width: sw + l + r
        height: sh
        preferredRendererType: Shape.CurveRenderer


        ShapePath {
            fillColor: Theme.island
            strokeWidth: -1
            startX: 0
            startY: 0

            PathLine {
                x: d.l + d.sw + d.r
                y: 0
            }
            PathArc {
                x: d.l + d.sw
                y: d.r
                radiusX: d.r
                radiusY: d.r
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: d.l + d.sw
                y: d.sh - d.b
            }
            PathArc {
                x: d.l + d.sw - d.b
                y: d.sh
                radiusX: d.b
                radiusY: d.b
            }
            PathLine {
                x: d.l + d.b
                y: d.sh
            }
            PathArc {
                x: d.l
                y: d.sh - d.b
                radiusX: d.b
                radiusY: d.b
            }
            PathLine {
                x: d.l
                y: d.l
            }
            PathArc {
                x: 0
                y: 0
                radiusX: d.l
                radiusY: d.l
                direction: PathArc.Counterclockwise
            }
        }
    }
}

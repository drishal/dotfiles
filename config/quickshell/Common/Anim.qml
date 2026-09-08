import QtQuick
import qs.Common

// Material 3 Expressive motion. `type` picks a (duration, curve) pair so every
// animation in the shell speaks one vocabulary: spatial curves overshoot and
// settle, effects curves never do.
NumberAnimation {
    id: root

    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial,
        FastEffects,
        DefaultEffects,
        SlowEffects,
        StandardAccel,
        EmphasizedAccel
    }

    property int type: Anim.DefaultSpatial

    duration: Theme.animDurations[root.type] ?? 400
    // easing.type must be assigned before the curve — a later type assignment
    // would reset it.
    easing.type: Easing.Bezier
    easing.bezierCurve: Theme.animCurves[root.type] ?? Theme.curveStandard
}

import QtQuick
import qs.Common

// Colour transitions always use the slow-effects curve, so palette swaps and
// hover tints cross-fade instead of snapping.
ColorAnimation {
    duration: Theme.animDurations[Anim.SlowEffects]
    easing.type: Easing.Bezier
    easing.bezierCurve: Theme.animCurves[Anim.SlowEffects]
}

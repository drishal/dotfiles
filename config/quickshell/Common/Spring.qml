pragma ComponentBehavior: Bound
import QtQuick

// Critically-damped spring integrator over a small vector (x, width, height).
// Unlike a Behavior, retargeting mid-flight keeps the current velocity, so a
// popout chasing a moving anchor never restarts from a standstill.
Item {
    id: root

    property real stiffness: 560
    property real damping: 37
    property real mass: 1
    property bool instant: false

    property real posEpsilon: 0.05
    property real velEpsilon: 0.05
    readonly property real maxFrame: 1 / 30
    readonly property real step: 1 / 240

    property real x1: 0
    property real w: 0
    property real h: 0

    property real targetX1: 0
    property real targetW: 0
    property real targetH: 0

    property real vx: 0
    property real vw: 0
    property real vh: 0

    readonly property bool settled: Math.abs(targetX1 - x1) < posEpsilon && Math.abs(targetW - w) < posEpsilon && Math.abs(targetH - h) < posEpsilon && Math.abs(vx) < velEpsilon && Math.abs(vw) < velEpsilon && Math.abs(vh) < velEpsilon

    function settle() {
        x1 = targetX1;
        w = targetW;
        h = targetH;
        vx = vw = vh = 0;
    }

    function retarget(nx, nw, nh) {
        targetX1 = nx;
        targetW = nw;
        targetH = nh;
        if (instant)
            settle();
    }

    visible: false

    FrameAnimation {
        running: !root.settled && !root.instant

        onTriggered: {
            let remaining = Math.min(frameTime, root.maxFrame);
            const k = root.stiffness;
            const c = root.damping;
            const m = Math.max(0.0001, root.mass);

            while (remaining > 0) {
                const dt = Math.min(root.step, remaining);
                remaining -= dt;

                root.vx += ((root.targetX1 - root.x1) * k - root.vx * c) / m * dt;
                root.vw += ((root.targetW - root.w) * k - root.vw * c) / m * dt;
                root.vh += ((root.targetH - root.h) * k - root.vh * c) / m * dt;

                root.x1 += root.vx * dt;
                root.w += root.vw * dt;
                root.h += root.vh * dt;
            }

            // Snap here rather than from onSettledChanged — writing the tracked
            // values from a handler on a property derived from them loops.
            if (root.settled)
                root.settle();
        }
    }
}

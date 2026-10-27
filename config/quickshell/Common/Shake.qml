pragma ComponentBehavior: Bound
import QtQuick

// Damped head shake for a rejected input. A Translate to put in the target's
// `transform`; call shake(). The one place with raw durations: an
// oscillation has no Anim type, and each swing is shorter than the last.
Translate {
    id: root

    function shake() {
        anim.restart();
    }

    property SequentialAnimation anim: SequentialAnimation {
        NumberAnimation {
            target: root
            property: "x"
            to: -14
            duration: 60
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "x"
            to: 11
            duration: 80
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root
            property: "x"
            to: -7
            duration: 75
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root
            property: "x"
            to: 4
            duration: 70
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root
            property: "x"
            to: 0
            duration: 90
            easing.type: Easing.OutQuad
        }
    }
}

import QtQuick

// Loader that fades out, swaps content, then fades in — so replacing a panel's
// body reads as one move instead of a hard cut.
Loader {
    id: root

    property Component sourceComp
    property bool ready

    asynchronous: true

    Component.onCompleted: {
        ready = true;
        sourceComponent = sourceComp;
    }
    onSourceCompChanged: if (ready)
        swap.restart()

    SequentialAnimation {
        id: swap

        running: false

        Anim {
            target: root
            property: "opacity"
            to: 0
            type: Anim.FastEffects
        }
        ScriptAction {
            script: root.sourceComponent = root.sourceComp
        }
        Anim {
            target: root
            property: "opacity"
            to: 1
            type: Anim.DefaultEffects
        }
    }
}

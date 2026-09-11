pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs.Common

// FadeFlickable's edge treatment on a ListView, for lists long enough that
// instantiating every row matters — a ListView only builds what is visible and
// recycles as it scrolls.
ListView {
    id: root

    property real fadeSize: 0.07

    property real topFade: atYBeginning ? 0 : 1
    property real bottomFade: atYEnd ? 0 : 1

    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    orientation: ListView.Vertical
    reuseItems: true

    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: fadeMask
        maskSpreadAtMin: 1

        Item {
            id: fadeMask

            anchors.fill: parent
            layer.enabled: true
            visible: false

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Vertical

                    GradientStop {
                        position: 0
                        color: Qt.rgba(0, 0, 0, 1 - root.topFade)
                    }
                    GradientStop {
                        position: root.fadeSize
                        color: "black"
                    }
                    GradientStop {
                        position: 1 - root.fadeSize
                        color: "black"
                    }
                    GradientStop {
                        position: 1
                        color: Qt.rgba(0, 0, 0, 1 - root.bottomFade)
                    }
                }
            }
        }
    }

    Behavior on topFade {
        Anim {
            type: Anim.SlowEffects
        }
    }
    Behavior on bottomFade {
        Anim {
            type: Anim.SlowEffects
        }
    }
}

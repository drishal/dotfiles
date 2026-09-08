import QtQuick
import QtQuick.Effects
import qs.Common

// Flickable whose top and bottom edges fade out, and only while there is
// actually content scrolled off in that direction — so a short list stays crisp
// and a long one never hard-cuts at the container edge.
Flickable {
    id: root

    property real fadeSize: 0.07

    property real topFade: atYBeginning ? 0 : 1
    property real bottomFade: atYEnd ? 0 : 1

    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick

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

pragma ComponentBehavior: Bound
//@ pragma UseQApplication
import Quickshell
import qs.Modules

ShellRoot {
    FloatingWindow {
        implicitWidth: 1600
        implicitHeight: 900

        LockSurface {
            anchors.fill: parent
        }
    }
}

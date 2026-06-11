import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Thin launcher for the Hermes desktop app.
//
// The chat UI used to live here as a popout + detached FloatingWindow backed by
// a HermesService. It now runs as its own standalone Quickshell process
// (config/HermesApp, launched via the `hermes-app` wrapper), so this plugin is
// just a bar button: a robot icon that opens the app on click.
PluginComponent {
    id: root

    function launchHermes() {
        // Go through a shell so PATH resolves `hermes-app` from the user profile,
        // matching how the rest of the toolchain is invoked.
        Quickshell.execDetached(["sh", "-c", "hermes-app"])
    }

    // No popout — a click launches the app instead of toggling one.
    pillClickAction: () => root.launchHermes()

    horizontalBarPill: Component {
        DankIcon {
            name: "smart_toy"
            size: Theme.iconSize - 4
            color: Theme.surfaceText
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "smart_toy"
            size: Theme.iconSize - 4
            color: Theme.surfaceText
        }
    }

    // Control-center tile doubles as a launch button.
    ccWidgetIcon: "smart_toy"
    ccWidgetPrimaryText: "Hermes"
    ccWidgetSecondaryText: "Open chat"
    ccWidgetIsToggle: false
    onCcWidgetToggled: root.launchHermes()
}

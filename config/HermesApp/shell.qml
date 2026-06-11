import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import "services"
import "components"

// Standalone Hermes desktop app.
//
// Run with:  qs -p config/HermesApp/shell.qml   (or the packaged wrapper).
//
// This is the detached-window experience the DMS plugin offered, lifted out
// into its own Quickshell process so it no longer depends on Dank Material
// Shell being installed. One HermesService backs a single FloatingWindow.
//
// Settings persist to ~/.config/HermesApp/settings.json via FileView/JsonAdapter,
// mirroring what PluginService.savePluginData used to do inside DMS.
ShellRoot {
    id: shell

    readonly property string configDir: Quickshell.env("HOME") + "/.config/HermesApp"
    readonly property string settingsPath: configDir + "/settings.json"

    // FileView can't create parent dirs, so make sure the config dir exists
    // before the adapter tries to write back.
    Process {
        id: mkdirProc
        running: true
        command: ["mkdir", "-p", shell.configDir]
    }

    FileView {
        id: settingsFile
        path: shell.settingsPath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        // Missing file on first run is expected — JsonAdapter defaults apply
        // and the first writeAdapter() creates it.
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter()
        }

        JsonAdapter {
            id: settings
            property string apiBaseUrl: "http://127.0.0.1:8642"
            property string apiKey: ""
            property string hermesHome: "~/.hermes"
            property string selectedModel: ""
        }
    }

    HermesService {
        id: hermesService
        apiBaseUrl: settings.apiBaseUrl
        apiKey: settings.apiKey
        hermesHome: settings.hermesHome
        selectedModel: settings.selectedModel
    }

    FloatingWindow {
        id: chatWindow
        visible: true
        title: "Hermes Agent"
        implicitWidth: 1100
        implicitHeight: 760
        minimumSize: Qt.size(720, 480)
        color: Theme.surfaceContainer

        // This window IS the app — closing it should terminate the process, not
        // leave a headless instance behind. The launcher relaunches on demand.
        onClosed: Qt.quit()

        ChatContent {
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            hermesService: hermesService
            apiBaseUrl: settings.apiBaseUrl
            apiKey: settings.apiKey
            hermesHome: settings.hermesHome
            selectedModel: settings.selectedModel
            expanded: true

            onSaved: (url, key, home, mdl) => {
                settings.apiBaseUrl = url
                settings.apiKey = key
                settings.hermesHome = home
                settings.selectedModel = mdl
            }

            // No popout to collapse into here — the window is the app, so the
            // collapse button just quits.
            onExpandToggled: Qt.quit()
        }
    }
}

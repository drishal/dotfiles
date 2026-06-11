import QtQuick
import qs.Common
import "../components"

// Top-level window for the standalone Hermes app. Replaces the Quickshell
// ShellRoot + FloatingWindow. Closing it quits the process (Qt's
// quitOnLastWindowClosed), so the DMS launcher reopens it cleanly.
Window {
    id: win

    visible: true
    width: 1100
    height: 760
    minimumWidth: 720
    minimumHeight: 480
    title: "Hermes Agent"
    color: Theme.surfaceContainer

    HermesService {
        id: svc
        backend: hermesBackend
    }

    ChatContent {
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        hermesService: svc
        apiBaseUrl: svc.apiBaseUrl
        apiKey: svc.apiKey
        hermesHome: svc.hermesHome
        selectedModel: svc.selectedModel
        expanded: true

        onSaved: (url, key, home, mdl) => hermesBackend.updateSettings(url, key, home, mdl)

        // No popout to fold into — the window is the app, so collapse quits.
        onExpandToggled: Qt.quit()
    }
}

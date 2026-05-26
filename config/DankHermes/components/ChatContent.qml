import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    required property var hermesService
    property string apiBaseUrl: ""
    property string apiKey: ""
    property string hermesHome: ""
    property string selectedModel: ""

    // True when rendered inside the detached FloatingWindow — flips the
    // ChatArea expand icon from "open_in_full" to "close_fullscreen".
    property bool expanded: false

    // Per-instance settings-panel visibility so the popout and the floating
    // window can be in different views without affecting each other.
    property bool showSettings: false

    signal saved(string apiBaseUrl, string apiKey, string hermesHome, string selectedModel)
    signal expandToggled()

    Row {
        anchors.fill: parent
        spacing: 0
        clip: true

        SessionSidebar {
            id: sidebar
            width: 180
            height: parent.height
            hermesService: root.hermesService
            currentSessionId: root.hermesService.currentSessionId
            settingsActive: root.showSettings

            onSessionSelected: (sessionId) => {
                root.showSettings = false
                root.hermesService.loadMessages(sessionId)
            }
            onNewChatRequested: {
                root.showSettings = false
                root.hermesService.newChat()
            }
            onSettingsRequested: root.showSettings = !root.showSettings
        }

        Rectangle {
            width: 1
            height: parent.height
            color: Theme.outlineVariant
        }

        Item {
            width: parent.width - 180 - 1
            height: parent.height

            ChatArea {
                anchors.fill: parent
                visible: !root.showSettings
                hermesService: root.hermesService
                expanded: root.expanded
                onExpandToggled: root.expandToggled()
            }

            SettingsPanel {
                anchors.fill: parent
                visible: root.showSettings
                apiBaseUrl: root.apiBaseUrl
                apiKey: root.apiKey
                hermesHome: root.hermesHome
                selectedModel: root.selectedModel

                onSaved: (url, key, home, mdl) => root.saved(url, key, home, mdl)
                onClosed: root.showSettings = false
            }
        }
    }
}

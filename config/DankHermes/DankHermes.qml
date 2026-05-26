import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./services"
import "./components"

PluginComponent {
    id: root

    // ── Plugin Data ────────────────────────────────────────────

    property string apiBaseUrl: pluginService
        ? pluginService.loadPluginData("dankHermes", "apiBaseUrl", "http://127.0.0.1:8642")
        : "http://127.0.0.1:8642"
    property string hermesHome: pluginService
        ? pluginService.loadPluginData("dankHermes", "hermesHome", "~/.hermes")
        : "~/.hermes"
    property string apiKey: pluginService
        ? pluginService.loadPluginData("dankHermes", "apiKey", "")
        : ""
    property string selectedModel: pluginService
        ? pluginService.loadPluginData("dankHermes", "selectedModel", "")
        : ""

    // ── Service Instance ───────────────────────────────────────

    Component.onCompleted: {
        console.info("DankHermes: plugin created, hermesHome=", hermesHome)
    }

    HermesService {
        id: hermesService
        apiBaseUrl: root.apiBaseUrl
        hermesHome: root.hermesHome
        apiKey: root.apiKey
        selectedModel: root.selectedModel
    }

    // Components created by PluginComponent/PopoutComponent may not retain
    // the local id lookup context, so expose the service through root.
    readonly property var hermesApi: hermesService

    // ── Bar Pill Config ────────────────────────────────────────

    popoutWidth: 660
    popoutHeight: 520

    // ── Horizontal Bar Pill ────────────────────────────────────

    horizontalBarPill: Component {
        MouseArea {
            implicitWidth: pillRow.implicitWidth + Theme.spacingS
            implicitHeight: pillRow.implicitHeight
            acceptedButtons: Qt.MiddleButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) {
                    root.closePopout()
                }
            }

            Row {
                id: pillRow
                spacing: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    name: "smart_toy"
                    size: Theme.iconSize - 6
                    color: Theme.surfaceText
                }

                // Status dot
                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    color: hermesService.connected ? Theme.primary : Theme.error
                    anchors.verticalCenter: parent.verticalCenter

                    SequentialAnimation on opacity {
                        running: hermesService.isRunning
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.3; duration: 700 }
                        NumberAnimation { from: 0.3; to: 1; duration: 700 }
                    }
                }

                // Model name (compact)
                StyledText {
                    visible: root.barConfig?.noBackground ?? false ? false : true
                    text: hermesService.connected
                          ? (hermesService.isRunning ? "…" : (hermesService.currentModel || "Hermes"))
                          : "Offline"
                    color: hermesService.connected ? Theme.surfaceText : Theme.error
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // ── Vertical Bar Pill ──────────────────────────────────────

    verticalBarPill: Component {
        MouseArea {
            implicitWidth: pillCol.implicitWidth
            implicitHeight: pillCol.implicitHeight
            acceptedButtons: Qt.MiddleButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            Column {
                id: pillCol
                spacing: 2
                anchors.horizontalCenter: parent.horizontalCenter

                DankIcon {
                    name: "smart_toy"
                    size: Theme.iconSize - 4
                    color: Theme.surfaceText
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    color: hermesService.connected ? Theme.primary : Theme.error
                    anchors.horizontalCenter: parent.horizontalCenter

                    SequentialAnimation on opacity {
                        running: hermesService.isRunning
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.3; duration: 700 }
                        NumberAnimation { from: 0.3; to: 1; duration: 700 }
                    }
                }
            }
        }
    }

    // ── Popout Content ─────────────────────────────────────────

    popoutContent: Component {
        PopoutComponent {
            id: popout

            property alias showSettings: popoutContent.showSettings

            headerText: popout.showSettings ? "Hermes Settings" : "Hermes Agent v2"
            detailsText: popout.showSettings
                ? "Configure gateway"
                : (root.hermesApi.connected
                    ? (root.hermesApi.isRunning ? "Running…" : (root.hermesApi.currentModel || "Connected"))
                    : "Disconnected")
            showCloseButton: true

            ChatContent {
                id: popoutContent
                width: parent.width
                height: 430
                hermesService: root.hermesApi
                apiBaseUrl: root.apiBaseUrl
                apiKey: root.apiKey
                hermesHome: root.hermesHome
                selectedModel: root.selectedModel
                expanded: false

                onSaved: (url, key, home, mdl) => {
                    root.apiBaseUrl = url
                    root.apiKey = key
                    root.hermesHome = home
                    root.selectedModel = mdl
                }

                onExpandToggled: {
                    chatWindow.visible = true
                    root.closePopout()
                }
            }
        }
    }

    // ── Detached "expand" window ───────────────────────────────
    // Real toplevel — resizable, draggable, real decorations. Shares the same
    // HermesService instance as the popout, so messages, sessions, and settings
    // stay in sync between the two views.

    FloatingWindow {
        id: chatWindow
        visible: false
        width: 1100
        height: 760
        title: "Hermes Agent"
        minimumSize: Qt.size(720, 480)
        color: Theme.surfaceContainer

        ChatContent {
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            hermesService: root.hermesApi
            apiBaseUrl: root.apiBaseUrl
            apiKey: root.apiKey
            hermesHome: root.hermesHome
            selectedModel: root.selectedModel
            expanded: true

            onSaved: (url, key, home, mdl) => {
                root.apiBaseUrl = url
                root.apiKey = key
                root.hermesHome = home
                root.selectedModel = mdl
            }

            onExpandToggled: chatWindow.visible = false
        }
    }

    // ── Control Center Widget ──────────────────────────────────

    ccWidgetIcon: hermesService.connected ? "smart_toy" : "smart_toy"
    ccWidgetPrimaryText: "Hermes"
    ccWidgetSecondaryText: hermesService.connected
        ? (hermesService.isRunning ? "Running…" : (hermesService.currentModel || "Ready"))
        : "Offline"
    ccWidgetIsActive: hermesService.connected

    // ── Save settings when they change ─────────────────────────

    onApiBaseUrlChanged: {
        if (pluginService) pluginService.savePluginData("dankHermes", "apiBaseUrl", apiBaseUrl)
    }
    onHermesHomeChanged: {
        if (pluginService) pluginService.savePluginData("dankHermes", "hermesHome", hermesHome)
    }
    onApiKeyChanged: {
        if (pluginService) pluginService.savePluginData("dankHermes", "apiKey", apiKey)
    }
    onSelectedModelChanged: {
        if (pluginService) pluginService.savePluginData("dankHermes", "selectedModel", selectedModel)
    }

    // ── Refresh sessions when popout opens ─────────────────────

    Connections {
        target: PluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === "dankHermes") {
                root.apiBaseUrl = pluginService.loadPluginData("dankHermes", "apiBaseUrl", "http://127.0.0.1:8642")
                root.hermesHome = pluginService.loadPluginData("dankHermes", "hermesHome", "~/.hermes")
                root.apiKey = pluginService.loadPluginData("dankHermes", "apiKey", "")
                root.selectedModel = pluginService.loadPluginData("dankHermes", "selectedModel", "")
            }
        }
    }
}

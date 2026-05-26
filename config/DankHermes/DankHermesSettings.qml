import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "dankHermes"

    StyledText {
        width: parent.width
        text: "Hermes Agent"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure the local Hermes API used by the DankBar chat widget. Start the API with `hermes gateway run`; the API server listens on 127.0.0.1:8642 by default."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "apiBaseUrl"
        label: "API Base URL"
        description: "Hermes gateway API server address."
        placeholder: "http://127.0.0.1:8642"
        defaultValue: "http://127.0.0.1:8642"
    }

    StringSetting {
        settingKey: "hermesHome"
        label: "Hermes home"
        description: "Directory containing state.db for session history."
        placeholder: "~/.hermes"
        defaultValue: "~/.hermes"
    }

    StringSetting {
        settingKey: "apiKey"
        label: "API key (optional)"
        description: "Only needed if the API server has authentication enabled. Stored in DMS plugin settings."
        placeholder: "leave empty for local default"
        defaultValue: ""
    }

    StyledRect {
        width: parent.width
        height: infoText.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        StyledText {
            id: infoText
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            text: "Features: session sidebar from ~/.hermes/state.db, /v1/runs streaming, tool call events, reasoning events, approvals, and stop."
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap
        }
    }
}

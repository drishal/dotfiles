import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property string apiBaseUrl: ""
    property string apiKey: ""
    property string hermesHome: ""
    property string selectedModel: ""

    signal closed()
    signal saved(string apiBaseUrl, string apiKey, string hermesHome, string selectedModel)

    property string _editBaseUrl: apiBaseUrl
    property string _editApiKey: apiKey
    property string _editHermesHome: hermesHome
    property string _editModel: selectedModel

    onApiBaseUrlChanged: _editBaseUrl = apiBaseUrl
    onApiKeyChanged: _editApiKey = apiKey
    onHermesHomeChanged: _editHermesHome = hermesHome
    onSelectedModelChanged: _editModel = selectedModel

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        color: Theme.surfaceContainer
        radius: Theme.cornerRadius
        border.width: 1
        border.color: Theme.outlineMedium

        Flickable {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            contentHeight: contentCol.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: contentCol
                width: parent.width
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankIcon {
                        name: "tune"
                        size: 20
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Hermes Settings"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                }

                Column {
                    width: parent.width
                    spacing: 4

                    StyledText {
                        text: "API Base URL"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        width: parent.width
                        height: 36
                        color: Theme.surfaceContainerHighest
                        radius: Math.max(4, Theme.cornerRadius / 2)
                        border.width: baseUrlInput.activeFocus ? 1 : 0
                        border.color: Theme.primary

                        TextInput {
                            id: baseUrlInput
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingS
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            selectionColor: Theme.primary
                            selectedTextColor: Theme.onPrimary
                            text: root._editBaseUrl
                            onTextChanged: root._editBaseUrl = text
                            clip: true

                            StyledText {
                                visible: baseUrlInput.text.length === 0 && !baseUrlInput.activeFocus
                                text: "http://127.0.0.1:8642"
                                color: Theme.surfaceTextMedium
                                font.pixelSize: Theme.fontSizeMedium
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: "Hermes gateway address. Default port is 8642."
                        color: Theme.surfaceTextMedium
                        font.pixelSize: Theme.fontSizeSmall - 1
                        wrapMode: Text.WordWrap
                    }
                }

                Column {
                    width: parent.width
                    spacing: 4

                    Item {
                        width: parent.width
                        height: 20

                        StyledText {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "API Key"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: revealText.implicitWidth + Theme.spacingS * 2
                            height: 20
                            radius: 10
                            color: revealMouse.containsMouse ? Theme.surfaceHover : "transparent"

                            StyledText {
                                id: revealText
                                anchors.centerIn: parent
                                text: apiKeyInput.echoMode === TextInput.Password ? "Show" : "Hide"
                                color: Theme.primary
                                font.pixelSize: Theme.fontSizeSmall - 1
                            }

                            MouseArea {
                                id: revealMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    apiKeyInput.echoMode = apiKeyInput.echoMode === TextInput.Password
                                                           ? TextInput.Normal
                                                           : TextInput.Password
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 36
                        color: Theme.surfaceContainerHighest
                        radius: Math.max(4, Theme.cornerRadius / 2)
                        border.width: apiKeyInput.activeFocus ? 1 : 0
                        border.color: Theme.primary

                        TextInput {
                            id: apiKeyInput
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingS
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            selectionColor: Theme.primary
                            selectedTextColor: Theme.onPrimary
                            echoMode: TextInput.Password
                            text: root._editApiKey
                            onTextChanged: root._editApiKey = text
                            clip: true

                            StyledText {
                                visible: apiKeyInput.text.length === 0 && !apiKeyInput.activeFocus
                                text: "leave empty if auth is disabled"
                                color: Theme.surfaceTextMedium
                                font.pixelSize: Theme.fontSizeMedium
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: "From API_SERVER_KEY in ~/.hermes/.env. Sent as Bearer token."
                        color: Theme.surfaceTextMedium
                        font.pixelSize: Theme.fontSizeSmall - 1
                        wrapMode: Text.WordWrap
                    }
                }

                Column {
                    width: parent.width
                    spacing: 4

                    StyledText {
                        text: "Hermes Home"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        width: parent.width
                        height: 36
                        color: Theme.surfaceContainerHighest
                        radius: Math.max(4, Theme.cornerRadius / 2)
                        border.width: hermesHomeInput.activeFocus ? 1 : 0
                        border.color: Theme.primary

                        TextInput {
                            id: hermesHomeInput
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingS
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            selectionColor: Theme.primary
                            selectedTextColor: Theme.onPrimary
                            text: root._editHermesHome
                            onTextChanged: root._editHermesHome = text
                            clip: true

                            StyledText {
                                visible: hermesHomeInput.text.length === 0 && !hermesHomeInput.activeFocus
                                text: "~/.hermes"
                                color: Theme.surfaceTextMedium
                                font.pixelSize: Theme.fontSizeMedium
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: "Directory containing state.db for session history."
                        color: Theme.surfaceTextMedium
                        font.pixelSize: Theme.fontSizeSmall - 1
                        wrapMode: Text.WordWrap
                    }
                }

                Column {
                    width: parent.width
                    spacing: 4

                    StyledText {
                        text: "Default model (optional)"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        width: parent.width
                        height: 36
                        color: Theme.surfaceContainerHighest
                        radius: Math.max(4, Theme.cornerRadius / 2)
                        border.width: modelInput.activeFocus ? 1 : 0
                        border.color: Theme.primary

                        TextInput {
                            id: modelInput
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingS
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            selectionColor: Theme.primary
                            selectedTextColor: Theme.onPrimary
                            text: root._editModel
                            onTextChanged: root._editModel = text
                            clip: true

                            StyledText {
                                visible: modelInput.text.length === 0 && !modelInput.activeFocus
                                text: "e.g. GLM5, DeepSeek, Kimi-K2.6 — empty = gateway default"
                                color: Theme.surfaceTextMedium
                                font.pixelSize: Theme.fontSizeMedium
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: "Sent as `model` field on /v1/runs. Gateway uses its configured default if empty."
                        color: Theme.surfaceTextMedium
                        font.pixelSize: Theme.fontSizeSmall - 1
                        wrapMode: Text.WordWrap
                    }
                }

                Item { width: parent.width; height: Theme.spacingS }

                Row {
                    spacing: Theme.spacingS

                    Rectangle {
                        width: 96
                        height: 36
                        radius: Math.max(4, Theme.cornerRadius / 2)
                        color: saveMouse.containsMouse ? Theme.primaryPressed : Theme.primary

                        StyledText {
                            anchors.centerIn: parent
                            text: "Save"
                            color: Theme.primaryText
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: saveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.saved(root._editBaseUrl, root._editApiKey, root._editHermesHome, root._editModel)
                                root.closed()
                            }
                        }
                    }

                    Rectangle {
                        width: 96
                        height: 36
                        radius: Math.max(4, Theme.cornerRadius / 2)
                        color: cancelMouse.containsMouse ? Theme.surfaceHover : "transparent"
                        border.width: 1
                        border.color: Theme.outlineMedium

                        StyledText {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root._editBaseUrl = root.apiBaseUrl
                                root._editApiKey = root.apiKey
                                root._editHermesHome = root.hermesHome
                                root._editModel = root.selectedModel
                                root.closed()
                            }
                        }
                    }
                }
            }
        }
    }
}

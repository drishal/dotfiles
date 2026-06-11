import QtQuick
import qs.Common
import qs.Widgets

// Dashboard-style welcome screen shown when there are no messages yet.
// Renders the cached `welcomeInfo` blob produced by `welcome_info.py`.
Item {
    id: root

    required property var hermesService

    readonly property var info: hermesService && hermesService.welcomeInfo ? hermesService.welcomeInfo : ({})
    readonly property var toolsets: info && info.toolsets ? info.toolsets : []
    readonly property var skills: info && info.skills ? info.skills : ({ total: 0, categories: [] })
    readonly property var mcpServers: info && info.mcpServers ? info.mcpServers : []
    readonly property string version: info && info.version ? info.version : ""
    readonly property string updateAvailable: info && info.updateAvailable ? info.updateAvailable : ""
    readonly property int enabledToolsetCount: {
        let n = 0
        for (let i = 0; i < toolsets.length; i++) if (toolsets[i].enabled) n++
        return n
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        contentWidth: width
        contentHeight: contentCol.implicitHeight + Theme.spacingL * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Theme.spacingL
            spacing: Theme.spacingL

            // ── Header ─────────────────────────────────────────
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                DankIcon {
                    name: "smart_toy"
                    size: 44
                    color: Theme.primary
                    opacity: 0.85
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: "Hermes Agent"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    visible: root.version !== ""
                    text: "v" + root.version
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: "monospace"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Update pill
                Rectangle {
                    visible: root.updateAvailable !== ""
                    height: updateRow.implicitHeight + 6
                    width: updateRow.implicitWidth + 18
                    radius: height / 2
                    color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12)
                    border.width: 1
                    border.color: Theme.warning
                    anchors.horizontalCenter: parent.horizontalCenter

                    Row {
                        id: updateRow
                        anchors.centerIn: parent
                        spacing: 4

                        DankIcon {
                            name: "system_update_alt"
                            size: 12
                            color: Theme.warning
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.updateAvailable
                            color: Theme.warning
                            font.pixelSize: Theme.fontSizeSmall - 1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // ── Tools section ──────────────────────────────────
            Column {
                width: parent.width
                spacing: Theme.spacingS
                visible: root.toolsets.length > 0

                Row {
                    spacing: Theme.spacingS

                    DankIcon { name: "build"; size: 14; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                    StyledText {
                        text: "TOOLS"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall - 1
                        font.weight: Font.Medium
                        font.letterSpacing: 1.2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: "· " + root.enabledToolsetCount + " of " + root.toolsets.length + " enabled"
                        color: Theme.surfaceTextMedium
                        font.pixelSize: Theme.fontSizeSmall - 1
                        opacity: 0.7
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Flow {
                    width: parent.width
                    spacing: Theme.spacingXS

                    Repeater {
                        model: root.toolsets

                        delegate: Rectangle {
                            readonly property var ts: modelData
                            visible: ts && ts.enabled
                            height: 26
                            width: tsRow.implicitWidth + Theme.spacingM
                            radius: height / 2
                            color: Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: Theme.outlineVariant

                            Row {
                                id: tsRow
                                anchors.centerIn: parent
                                spacing: 5

                                DankIcon {
                                    name: ts ? (ts.icon || "build") : "build"
                                    size: 13
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: ts ? (ts.label || ts.name) : ""
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // Disabled-count chip
                    Rectangle {
                        visible: (root.toolsets.length - root.enabledToolsetCount) > 0
                        height: 26
                        width: disabledLabel.implicitWidth + Theme.spacingM
                        radius: height / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.outlineVariant

                        StyledText {
                            id: disabledLabel
                            anchors.centerIn: parent
                            text: "+" + (root.toolsets.length - root.enabledToolsetCount) + " disabled"
                            color: Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeSmall - 1
                            opacity: 0.6
                        }
                    }
                }
            }

            // ── Skills section ─────────────────────────────────
            Column {
                width: parent.width
                spacing: Theme.spacingS
                visible: root.skills && root.skills.total > 0

                Row {
                    spacing: Theme.spacingS

                    DankIcon { name: "auto_awesome"; size: 14; color: Theme.tertiary; anchors.verticalCenter: parent.verticalCenter }
                    StyledText {
                        text: "SKILLS"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall - 1
                        font.weight: Font.Medium
                        font.letterSpacing: 1.2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: "· " + (root.skills.total || 0) + " in " + (root.skills.categories ? root.skills.categories.length : 0) + " categories"
                        color: Theme.surfaceTextMedium
                        font.pixelSize: Theme.fontSizeSmall - 1
                        opacity: 0.7
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Flow {
                    width: parent.width
                    spacing: Theme.spacingXS

                    Repeater {
                        model: root.skills && root.skills.categories ? root.skills.categories : []

                        delegate: Rectangle {
                            readonly property var cat: modelData
                            height: 24
                            width: catLabel.implicitWidth + countBadge.width + Theme.spacingS + 12
                            radius: height / 2
                            color: Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: Theme.outlineVariant

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                StyledText {
                                    id: catLabel
                                    text: cat ? cat.category : ""
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    id: countBadge
                                    height: 14
                                    width: countText.implicitWidth + 8
                                    radius: 7
                                    color: Qt.rgba(Theme.tertiary.r, Theme.tertiary.g, Theme.tertiary.b, 0.18)
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledText {
                                        id: countText
                                        anchors.centerIn: parent
                                        text: cat ? cat.count : 0
                                        color: Theme.tertiary
                                        font.pixelSize: Theme.fontSizeSmall - 2
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── MCP section ────────────────────────────────────
            Column {
                width: parent.width
                spacing: Theme.spacingS
                visible: root.mcpServers.length > 0

                Row {
                    spacing: Theme.spacingS

                    DankIcon { name: "hub"; size: 14; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                    StyledText {
                        text: "MCP SERVERS"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall - 1
                        font.weight: Font.Medium
                        font.letterSpacing: 1.2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: "· " + root.mcpServers.length + " connected"
                        color: Theme.surfaceTextMedium
                        font.pixelSize: Theme.fontSizeSmall - 1
                        opacity: 0.7
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Flow {
                    width: parent.width
                    spacing: Theme.spacingXS

                    Repeater {
                        model: root.mcpServers

                        delegate: Rectangle {
                            readonly property var srv: modelData
                            height: 26
                            width: mcpRow.implicitWidth + Theme.spacingM
                            radius: height / 2
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            border.width: 1
                            border.color: Theme.primary

                            Row {
                                id: mcpRow
                                anchors.centerIn: parent
                                spacing: 5

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: srv && srv.enabled ? Theme.primary : Theme.error
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: srv ? srv.name : ""
                                    color: Theme.primary
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
            }

            // ── Hint ───────────────────────────────────────────
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                text: hermesService && hermesService.connected
                      ? "Message Hermes below — Shift+Enter for newline"
                      : "Gateway not reachable — start it with `hermes gateway run`"
                color: hermesService && hermesService.connected ? Theme.surfaceTextMedium : Theme.error
                font.pixelSize: Theme.fontSizeSmall
                font.italic: true
                opacity: 0.85
            }
        }
    }
}

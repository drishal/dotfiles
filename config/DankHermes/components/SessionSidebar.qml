import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    required property var hermesService
    required property string currentSessionId
    property bool settingsActive: false
    property string searchQuery: ""

    signal sessionSelected(string sessionId)
    signal newChatRequested()
    signal settingsRequested()

    function _groupLabelFor(epochSecs) {
        if (!epochSecs) return "Older"
        const now = new Date()
        const d = new Date(epochSecs * 1000)
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
        const dayMs = 24 * 3600 * 1000
        const dayStart = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()
        const delta = today - dayStart
        if (delta <= 0) return "Today"
        if (delta <= dayMs) return "Yesterday"
        if (delta <= 6 * dayMs) return "This week"
        if (delta <= 29 * dayMs) return "This month"
        return "Older"
    }

    function _rebuildFiltered() {
        const src = hermesService.sessionList
        const q = searchQuery.trim().toLowerCase()
        filteredSessions.clear()
        for (let i = 0; i < src.count; i++) {
            const s = src.get(i)
            const title = (s.title || "").toLowerCase()
            const mname = (s.modelName || "").toLowerCase()
            if (q && title.indexOf(q) === -1 && mname.indexOf(q) === -1) continue
            filteredSessions.append({
                "sessionId": s.sessionId,
                "title": s.title,
                "modelName": s.modelName,
                "startedAt": s.startedAt,
                "messageCount": s.messageCount,
                "groupLabel": _groupLabelFor(s.startedAt)
            })
        }
    }

    onSearchQueryChanged: _rebuildFiltered()
    Component.onCompleted: _rebuildFiltered()

    Connections {
        target: hermesService.sessionList
        function onCountChanged() { _rebuildFiltered() }
    }

    ListModel { id: filteredSessions; dynamicRoles: true }

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceContainerHigh
        radius: Theme.cornerRadius
        border.width: 1
        border.color: Theme.outlineMedium

        Rectangle {
            id: newChatButton
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Theme.spacingXS
            height: 36
            color: newChatMouse.containsMouse ? Theme.primaryPressed : Theme.primaryBackground
            radius: Math.max(4, Theme.cornerRadius / 2)

            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingS
                anchors.rightMargin: Theme.spacingS
                spacing: Theme.spacingXS

                DankIcon {
                    name: "add"
                    size: 18
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "New Chat"
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: newChatMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.newChatRequested()
            }
        }

        Rectangle {
            id: searchBox
            anchors.top: newChatButton.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Theme.spacingXS
            anchors.leftMargin: Theme.spacingXS
            anchors.rightMargin: Theme.spacingXS
            height: 28
            color: Theme.surfaceContainerHighest
            radius: Math.max(4, Theme.cornerRadius / 2)
            border.width: searchInput.activeFocus ? 1 : 0
            border.color: Theme.primary

            Row {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 4

                DankIcon {
                    name: "search"
                    size: 12
                    color: Theme.surfaceTextMedium
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: searchInput
                    width: parent.width - 30 - (clearBtn.visible ? clearBtn.width + 4 : 0)
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.onPrimary
                    clip: true
                    anchors.verticalCenter: parent.verticalCenter
                    onTextChanged: root.searchQuery = text

                    StyledText {
                        visible: searchInput.text.length === 0 && !searchInput.activeFocus
                        text: "Search sessions…"
                        color: Theme.surfaceTextMedium
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    id: clearBtn
                    visible: searchInput.text.length > 0
                    width: 16
                    height: 16
                    radius: 8
                    color: clearMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    DankIcon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 10
                        color: Theme.surfaceTextMedium
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchInput.text = ""
                    }
                }
            }
        }

        Rectangle {
            id: topDivider
            anchors.top: searchBox.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Theme.spacingXS
            anchors.leftMargin: Theme.spacingXS
            anchors.rightMargin: Theme.spacingXS
            height: 1
            color: Theme.outlineVariant
        }

        Rectangle {
            id: settingsButton
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Theme.spacingXS
            height: 32
            color: root.settingsActive
                   ? Theme.primarySelected
                   : (settingsMouse.containsMouse ? Theme.surfaceHover : "transparent")
            radius: Math.max(4, Theme.cornerRadius / 2)

            Row {
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                DankIcon {
                    name: "tune"
                    size: 16
                    color: root.settingsActive ? Theme.primary : Theme.surfaceTextMedium
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "Settings"
                    color: root.settingsActive ? Theme.primary : Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: root.settingsActive ? Font.Medium : Font.Normal
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: settingsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.settingsRequested()
            }
        }

        Rectangle {
            id: bottomDivider
            anchors.bottom: settingsButton.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottomMargin: Theme.spacingXS
            anchors.leftMargin: Theme.spacingXS
            anchors.rightMargin: Theme.spacingXS
            height: 1
            color: Theme.outlineVariant
        }

        ListView {
            id: sessionListView
            anchors.top: topDivider.bottom
            anchors.bottom: bottomDivider.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.spacingXS
            anchors.rightMargin: Theme.spacingXS
            anchors.topMargin: Theme.spacingXS
            anchors.bottomMargin: Theme.spacingXS
            clip: true
            spacing: 2
            model: filteredSessions
            boundsBehavior: Flickable.StopAtBounds

            section.property: "groupLabel"
            section.criteria: ViewSection.FullString
            section.delegate: Item {
                width: sessionListView.width
                height: 18

                StyledText {
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: section
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall - 1
                    font.weight: Font.Medium
                    font.capitalization: Font.AllUppercase
                }
            }

            delegate: Rectangle {
                width: sessionListView.width
                height: sessionItemCol.height + Theme.spacingS * 2
                color: {
                    if (model.sessionId === root.currentSessionId && !root.settingsActive) return Theme.primarySelected
                    if (sessionMouse.containsMouse) return Theme.surfaceHover
                    return "transparent"
                }
                radius: Math.max(4, Theme.cornerRadius / 2)

                Column {
                    id: sessionItemCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Theme.spacingS
                    anchors.rightMargin: Theme.spacingS
                    spacing: 2

                    StyledText {
                        width: parent.width
                        text: model.title || "Untitled"
                        color: (model.sessionId === root.currentSessionId && !root.settingsActive) ? Theme.primary : Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: (model.sessionId === root.currentSessionId && !root.settingsActive) ? Font.Medium : Font.Normal
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    StyledText {
                        width: parent.width
                        text: {
                            const d = new Date(model.startedAt * 1000)
                            const dateStr = d.toLocaleDateString()
                            const mName = model.modelName || ""
                            if (mName && dateStr && dateStr !== "Invalid Date") {
                                return mName + " · " + dateStr
                            } else if (dateStr && dateStr !== "Invalid Date") {
                                return dateStr
                            } else if (mName) {
                                return mName
                            }
                            return ""
                        }
                        color: Theme.surfaceTextMedium
                        font.pixelSize: Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: sessionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sessionSelected(model.sessionId)
                }
            }

            Item {
                visible: filteredSessions.count === 0
                anchors.fill: parent

                StyledText {
                    anchors.centerIn: parent
                    text: root.searchQuery ? "No matches" : "No sessions"
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    font.italic: true
                }
            }
        }
    }
}

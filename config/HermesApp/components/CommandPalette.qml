import QtQuick
import qs.Common
import qs.Widgets

// Ctrl+K command palette: fuzzy-ish search over quick actions and recent
// sessions. Arrow keys move, Enter runs, Esc / click-outside closes.
Item {
    id: root
    anchors.fill: parent
    visible: opacity > 0
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    property bool open: false
    required property var hermesService
    property int selected: 0

    signal requestNewChat()
    signal requestSettings()
    signal requestStop()
    signal sessionChosen(string sessionId)

    function show() {
        open = true
        searchField.text = ""
        rebuild()
        Qt.callLater(() => searchField.forceActiveFocus())
    }
    function hide() {
        open = false
        searchField.focus = false
    }

    function rebuild() {
        const q = searchField.text.trim().toLowerCase()
        itemsModel.clear()

        const cmds = [
            { kind: "cmd", action: "new", label: "New Chat", icon: "add", sub: "Start a fresh conversation" },
            { kind: "cmd", action: "settings", label: "Settings", icon: "tune", sub: "Configure the gateway" }
        ]
        if (hermesService.isRunning)
            cmds.push({ kind: "cmd", action: "stop", label: "Stop Run", icon: "stop", sub: "Cancel the active run" })
        for (const c of cmds)
            if (!q || c.label.toLowerCase().indexOf(q) !== -1)
                itemsModel.append(c)

        const sl = hermesService.sessionList
        for (let i = 0; i < sl.count; i++) {
            const s = sl.get(i)
            const title = s.title || "Untitled"
            if (!q || title.toLowerCase().indexOf(q) !== -1)
                itemsModel.append({
                    kind: "session", action: "session",
                    label: title, icon: "chat",
                    sub: s.modelName || "", sessionId: s.sessionId
                })
        }
        selected = 0
    }

    function exec(i) {
        if (i < 0 || i >= itemsModel.count) return
        const it = itemsModel.get(i)
        hide()
        switch (it.action) {
        case "new":      requestNewChat(); break
        case "settings": requestSettings(); break
        case "stop":     requestStop(); break
        case "session":  sessionChosen(it.sessionId); break
        }
    }

    ListModel { id: itemsModel; dynamicRoles: true }

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        MouseArea { anchors.fill: parent; onClicked: root.hide() }
    }

    Rectangle {
        id: panel
        width: Math.min(560, parent.width - 80)
        height: Math.min(420, parent.height - 120)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 72
        color: Theme.surfaceContainerHigh
        radius: Theme.cornerRadius
        border.width: 1
        border.color: Theme.outlineMedium
        scale: root.open ? 1 : 0.96
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            spacing: Theme.spacingS

            // Search field
            Rectangle {
                width: parent.width
                height: 40
                color: Theme.surfaceContainerHighest
                radius: Math.max(6, Theme.cornerRadius / 2)
                border.width: searchField.activeFocus ? 1 : 0
                border.color: Theme.primary

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingS
                    anchors.rightMargin: Theme.spacingS
                    spacing: Theme.spacingS

                    DankIcon {
                        name: "search"; size: 18
                        color: Theme.surfaceTextMedium
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: searchField
                        width: parent.width - 30
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.onPrimary
                        clip: true
                        onTextChanged: root.rebuild()
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down) {
                                root.selected = Math.min(root.selected + 1, itemsModel.count - 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                root.selected = Math.max(root.selected - 1, 0)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.exec(root.selected)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                root.hide()
                                event.accepted = true
                            }
                        }

                        StyledText {
                            visible: searchField.text.length === 0
                            text: "Search commands and sessions…"
                            color: Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Results
            ListView {
                id: results
                width: parent.width
                height: parent.height - 40 - Theme.spacingS
                clip: true
                model: itemsModel
                currentIndex: root.selected
                boundsBehavior: Flickable.StopAtBounds
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: Rectangle {
                    width: results.width
                    height: 44
                    radius: Math.max(6, Theme.cornerRadius / 2)
                    color: index === root.selected
                           ? Theme.primarySelected
                           : (itemMouse.containsMouse ? Theme.surfaceHover : "transparent")
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingS
                        anchors.rightMargin: Theme.spacingS
                        spacing: Theme.spacingS

                        DankIcon {
                            name: model.icon
                            size: 18
                            color: model.kind === "session" ? Theme.surfaceTextMedium : Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 40
                            spacing: 0

                            StyledText {
                                width: parent.width
                                text: model.label
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                elide: Text.ElideRight
                            }
                            StyledText {
                                width: parent.width
                                visible: (model.sub || "") !== ""
                                text: model.sub || ""
                                color: Theme.surfaceTextMedium
                                font.pixelSize: Theme.fontSizeSmall - 1
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.selected = index; root.exec(index) }
                    }
                }

                StyledText {
                    visible: itemsModel.count === 0
                    anchors.centerIn: parent
                    text: "No matches"
                    color: Theme.surfaceTextMedium
                    font.italic: true
                }
            }
        }
    }
}

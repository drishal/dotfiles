import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets

Item {
    id: root

    required property var hermesService

    // Set true when this ChatArea is being rendered inside the detached
    // FloatingWindow. The expand button toggles its icon/tooltip accordingly.
    property bool expanded: false
    signal expandToggled()

    // ── Pasted image attachments ───────────────────────────────
    // List of {path, name} for images pulled off the clipboard. Cleared
    // after send. On send, each path is prepended to the message text as
    // [Attached image: <path>] so Hermes' file/vision tools can pick it up
    // (Hermes config has trust_recent_files: true / 600s window).
    property var attachedImages: []

    function scrollToBottom() {
        Qt.callLater(() => messageListView.positionViewAtEnd())
    }

    function removeAttachment(idx) {
        const next = attachedImages.slice()
        next.splice(idx, 1)
        attachedImages = next
    }

    function clearAttachments() {
        attachedImages = []
    }

    function buildOutgoingMessage(text) {
        if (!attachedImages.length) return text
        let prefix = ""
        for (const img of attachedImages) {
            prefix += "[Attached image: " + img.path + "]\n"
        }
        return prefix + text
    }

    function sendCurrent(text) {
        const payload = buildOutgoingMessage(text)
        hermesService.sendMessage(payload)
        clearAttachments()
    }

    Process {
        id: imagePasteProcess
        running: false
        // Writes the clipboard's image/png to /tmp/dms-paste-<unix-ms>.png if
        // present, and echoes the path on stdout. Empty stdout = clipboard had
        // no PNG image, which is the normal case for a text-only paste.
        command: ["sh", "-c",
            "TS=$(date +%s%3N); P=/tmp/dms-paste-$TS.png; " +
            "wl-paste --list-types 2>/dev/null | grep -q '^image/png$' || exit 0; " +
            "wl-paste --type image/png > \"$P\" 2>/dev/null && [ -s \"$P\" ] && echo \"$P\""
        ]
        stdout: SplitParser {
            onRead: data => {
                const path = (data || "").trim()
                if (!path) return
                const name = path.split("/").pop()
                root.attachedImages = root.attachedImages.concat([{ path: path, name: name }])
            }
        }
    }

    function tryPasteImage() {
        imagePasteProcess.running = false
        imagePasteProcess.running = true
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // ═══════════════════════════════════════════════════════
        //  MESSAGE LIST
        // ═══════════════════════════════════════════════════════

        ListView {
            id: messageListView
            width: parent.width
            height: parent.height - statusBar.height - inputRow.height - attachStrip.height
            clip: true
            spacing: Theme.spacingS
            leftMargin: Theme.spacingS
            rightMargin: Theme.spacingS
            topMargin: Theme.spacingS
            bottomMargin: Theme.spacingS

            model: hermesService.messageList
            boundsBehavior: Flickable.StopAtBounds

            onCountChanged: root.scrollToBottom()

            // Scroll-to-bottom button
            Rectangle {
                visible: messageListView.contentHeight > messageListView.height && messageListView.contentY < messageListView.contentHeight - messageListView.height - 50
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: Theme.spacingM
                width: 32
                height: 32
                radius: 16
                color: Theme.surfaceContainerHigh
                border.width: 1
                border.color: Theme.outlineMedium

                DankIcon {
                    anchors.centerIn: parent
                    name: "keyboard_arrow_down"
                    size: 18
                    color: Theme.surfaceText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.scrollToBottom()
                }
            }

            delegate: Item {
                width: messageListView.width - messageListView.leftMargin - messageListView.rightMargin
                height: contentLoader.height + Theme.spacingXS

                Loader {
                    id: contentLoader
                    width: parent.width
                    // Capture row data here — Components are declared outside the
                    // delegate, so they don't inherit the delegate's `model` context.
                    // Each loaded item reaches the row via `parent.msg`.
                    property var msg: model
                    sourceComponent: {
                        switch (msg ? msg.type : "") {
                        case "user":        return userMsgComponent
                        case "assistant":   return assistantMsgComponent
                        case "thinking":    return thinkingMsgComponent
                        case "tool_call":   return toolCallMsgComponent
                        case "tool_result": return toolResultMsgComponent
                        case "approval":    return approvalMsgComponent
                        default:            return null
                        }
                    }
                }
            }

            // ── Empty State ────────────────────────────────────
            Item {
                visible: messageListView.count === 0
                anchors.fill: parent

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "smart_toy"
                        size: 56
                        color: Theme.primary
                        opacity: 0.4
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    StyledText {
                        text: "Start a conversation with Hermes"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        visible: hermesService.connected && hermesService.currentModel
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: modelBadgeText.implicitHeight + Theme.spacingS * 2
                        width: modelBadgeText.implicitWidth + Theme.spacingM * 2
                        color: Theme.primaryBackground
                        radius: height / 2

                        StyledText {
                            id: modelBadgeText
                            anchors.centerIn: parent
                            text: hermesService.currentModel
                            color: Theme.primary
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                        }
                    }

                    StyledText {
                        visible: !hermesService.connected
                        text: "Gateway not reachable — start it with `hermes gateway run`"
                        color: Theme.error
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════
        //  STATUS BAR
        // ═══════════════════════════════════════════════════════

        Rectangle {
            id: statusBar
            width: parent.width
            height: 24
            color: "transparent"

            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingS
                anchors.rightMargin: Theme.spacingS
                spacing: Theme.spacingS

                // Connection dot
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: hermesService.connected ? Theme.primary : Theme.error
                    anchors.verticalCenter: parent.verticalCenter

                    SequentialAnimation on opacity {
                        running: hermesService.isRunning
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.3; duration: 800 }
                        NumberAnimation { from: 0.3; to: 1; duration: 800 }
                    }
                }

                StyledText {
                    text: hermesService.connected
                          ? (hermesService.isRunning ? "Running…" : hermesService.currentModel || "Ready")
                          : "Disconnected"
                    color: hermesService.connected ? Theme.surfaceTextMedium : Theme.error
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Token usage
                StyledText {
                    visible: hermesService.lastUsage && hermesService.lastUsage.total_tokens > 0
                    text: {
                        const u = hermesService.lastUsage
                        if (!u) return ""
                        const total = u.total_tokens || 0
                        return "· " + total + " tokens"
                    }
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: Math.max(0, parent.width - 360); height: 1 }

                // Session ID indicator
                StyledText {
                    visible: hermesService.currentSessionId !== ""
                    text: hermesService.currentSessionId.length > 12
                          ? hermesService.currentSessionId.substring(0, 12) + "…"
                          : hermesService.currentSessionId
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: "monospace"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    color: expandMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    DankIcon {
                        anchors.centerIn: parent
                        name: root.expanded ? "close_fullscreen" : "open_in_full"
                        size: 14
                        color: Theme.surfaceTextMedium
                    }

                    MouseArea {
                        id: expandMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expandToggled()
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════
        //  ATTACHMENT STRIP
        // ═══════════════════════════════════════════════════════

        Item {
            id: attachStrip
            width: parent.width
            height: root.attachedImages.length > 0 ? 64 : 0
            visible: root.attachedImages.length > 0
            clip: true

            Behavior on height {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            ListView {
                id: attachList
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingS
                anchors.rightMargin: Theme.spacingS
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                orientation: ListView.Horizontal
                spacing: Theme.spacingXS
                model: root.attachedImages
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    width: 56
                    height: 56
                    radius: Math.max(4, Theme.cornerRadius / 2)
                    color: Theme.surfaceContainerHighest
                    border.width: 1
                    border.color: Theme.outlineMedium
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: "file://" + modelData.path
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 2
                        width: 16
                        height: 16
                        radius: 8
                        color: removeMouse.containsMouse ? Theme.error : Qt.rgba(0, 0, 0, 0.55)

                        DankIcon {
                            anchors.centerIn: parent
                            name: "close"
                            size: 10
                            color: "white"
                        }

                        MouseArea {
                            id: removeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.removeAttachment(index)
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════
        //  INPUT ROW
        // ═══════════════════════════════════════════════════════

        Rectangle {
            id: inputRow
            width: parent.width
            height: Math.min(140, Math.max(44, chatInput.implicitHeight + 20))
            color: Theme.surfaceContainerHigh
            radius: Theme.cornerRadius
            border.width: 1
            border.color: chatInput.activeFocus ? Theme.primary : Theme.outlineMedium

            Behavior on height {
                NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
            }

            Rectangle {
                id: inputField
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: sendButton.left
                anchors.margins: Theme.spacingXS
                anchors.rightMargin: Theme.spacingXS
                color: Theme.surfaceContainerHighest
                radius: Theme.cornerRadius
                border.width: chatInput.activeFocus ? 1 : 0
                border.color: Theme.primary

                Flickable {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingS
                    anchors.rightMargin: Theme.spacingS
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    contentWidth: width
                    contentHeight: chatInput.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    TextEdit {
                        id: chatInput
                        width: parent.width
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.onPrimary
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        textFormat: TextEdit.PlainText
                        tabStopDistance: 32

                        Keys.onPressed: event => {
                            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                && !(event.modifiers & Qt.ShiftModifier)) {
                                event.accepted = true
                                if (chatInput.text.trim() || root.attachedImages.length > 0) {
                                    root.sendCurrent(chatInput.text)
                                    chatInput.text = ""
                                }
                            } else if (event.key === Qt.Key_V
                                       && (event.modifiers & Qt.ControlModifier)) {
                                // Try to pull an image off the clipboard alongside
                                // the regular text paste. If the clipboard has only
                                // text the process exits 0 with empty stdout and
                                // nothing gets attached. Don't preventDefault — let
                                // Qt's text paste run too.
                                root.tryPasteImage()
                            }
                        }

                        StyledText {
                            visible: chatInput.text.length === 0 && !chatInput.activeFocus
                            text: "Message Hermes…   (Shift+Enter for newline)"
                            color: Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.left: parent.left
                            anchors.top: parent.top
                        }
                    }
                }
            }

            Rectangle {
                id: sendButton
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: Theme.spacingXS
                anchors.bottomMargin: Theme.spacingXS
                width: hermesService.isRunning ? 72 : 36
                height: 36
                radius: height / 2
                color: {
                    if (hermesService.isRunning) return Theme.error
                    if (chatInput.text.trim()) return Theme.primary
                    return Theme.surfaceVariant
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    DankIcon {
                        name: hermesService.isRunning ? "stop" : "arrow_upward"
                        size: 20
                        color: {
                            if (hermesService.isRunning) return Theme.primaryText
                            if (chatInput.text.trim()) return Theme.primaryText
                            return Theme.surfaceTextMedium
                        }
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        visible: hermesService.isRunning
                        text: "Stop"
                        color: Theme.primaryText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (hermesService.isRunning) {
                            hermesService.stopRun()
                        } else if (chatInput.text.trim() || root.attachedImages.length > 0) {
                            root.sendCurrent(chatInput.text)
                            chatInput.text = ""
                        }
                    }
                }

                Behavior on width {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  MESSAGE DELEGATE COMPONENTS
    // ═══════════════════════════════════════════════════════════

    // ── User Message ───────────────────────────────────────────
    Component {
        id: userMsgComponent

        Item {
            id: umc
            width: parent.width
            readonly property var msg: parent ? parent.msg : null
            height: userBubble.height + (msgTime.visible ? 16 : 0)

            Rectangle {
                id: userBubble
                anchors.right: parent.right
                width: Math.min(userText.implicitWidth + Theme.spacingM * 2, parent.width * 0.85)
                height: userText.implicitHeight + Theme.spacingS * 2
                color: Theme.primary
                radius: Theme.cornerRadius

                TextEdit {
                    id: userText
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    text: umc.msg ? umc.msg.content : ""
                    color: Theme.primaryText
                    font.pixelSize: Theme.fontSizeMedium
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    readOnly: true
                    selectByMouse: true
                    selectionColor: Theme.onPrimary
                    selectedTextColor: Theme.primary
                    persistentSelection: true
                    HoverHandler {
                        cursorShape: Qt.IBeamCursor
                    }
                }
            }

            StyledText {
                id: msgTime
                anchors.top: userBubble.bottom
                anchors.right: userBubble.right
                anchors.topMargin: 2
                text: {
                    const d = new Date(((umc.msg && umc.msg.timestamp) || 0) * 1000)
                    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                }
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall - 1
                visible: umc.msg && umc.msg.timestamp > 0
            }
        }
    }

    // ── Assistant Message ──────────────────────────────────────
    Component {
        id: assistantMsgComponent

        Item {
            id: amc
            width: parent.width
            readonly property var msg: parent ? parent.msg : null
            readonly property bool streaming: msg ? !!msg.isStreaming : false
            readonly property string contentText: msg ? (msg.content || "") : ""
            readonly property bool hasContent: contentText.length > 0
            readonly property real msgDuration: msg ? (msg.duration || 0) : 0
            readonly property int msgTotalTokens: msg && msg.usage ? (msg.usage.total_tokens || 0) : 0
            readonly property int msgInTokens: msg && msg.usage ? (msg.usage.input_tokens || 0) : 0
            readonly property int msgOutTokens: msg && msg.usage ? (msg.usage.output_tokens || 0) : 0
            readonly property bool hasStats: !streaming && (msgDuration > 0 || msgTotalTokens > 0)
            height: assistantBubble.height + (msgTime.visible ? 16 : 0) + (statsRow.visible ? statsRow.height + 2 : 0)

            Rectangle {
                id: assistantBubble
                anchors.left: parent.left
                width: parent.width * 0.92
                height: bubbleContent.implicitHeight + Theme.spacingS * 2 + (amc.streaming ? 4 : 0)
                color: Theme.surfaceContainer
                radius: Theme.cornerRadius

                Item {
                    id: bubbleContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: Theme.spacingS
                    anchors.rightMargin: Theme.spacingS
                    anchors.topMargin: Theme.spacingS
                    implicitHeight: amc.streaming && !amc.hasContent
                        ? thinkingIndicator.height
                        : messageContent.implicitHeight + (amc.streaming ? cursorDot.height + 2 : 0)

                    Row {
                        id: thinkingIndicator
                        visible: amc.streaming && !amc.hasContent
                        spacing: Theme.spacingXS
                        anchors.left: parent.left

                        StyledText {
                            text: "Hermes is thinking…"
                            color: Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeMedium
                            font.italic: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MessageContent {
                        id: messageContent
                        visible: amc.hasContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        text: amc.contentText
                        isStreaming: amc.streaming
                    }

                    Rectangle {
                        id: cursorDot
                        visible: amc.streaming && amc.hasContent
                        anchors.left: messageContent.left
                        anchors.top: messageContent.bottom
                        anchors.topMargin: 2
                        width: 6
                        height: 14
                        radius: 2
                        color: Theme.primary

                        SequentialAnimation on opacity {
                            running: cursorDot.visible
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 0; duration: 500 }
                            NumberAnimation { from: 0; to: 1; duration: 500 }
                        }
                    }
                }
            }

            StyledText {
                id: msgTime
                anchors.top: assistantBubble.bottom
                anchors.left: assistantBubble.left
                anchors.topMargin: 2
                text: {
                    const d = new Date(((amc.msg && amc.msg.timestamp) || 0) * 1000)
                    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                }
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall - 1
                visible: amc.msg && amc.msg.timestamp > 0 && !amc.streaming
            }

            Row {
                id: statsRow
                anchors.top: msgTime.visible ? msgTime.bottom : assistantBubble.bottom
                anchors.left: assistantBubble.left
                anchors.topMargin: 1
                spacing: 6
                visible: amc.hasStats

                StyledText {
                    visible: amc.msgDuration > 0
                    text: amc.msgDuration < 1
                        ? (amc.msgDuration * 1000).toFixed(0) + "ms"
                        : amc.msgDuration.toFixed(1) + "s"
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall - 1
                    opacity: 0.8
                }

                StyledText {
                    visible: amc.msgDuration > 0 && amc.msgTotalTokens > 0
                    text: "·"
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall - 1
                    opacity: 0.5
                }

                StyledText {
                    visible: amc.msgTotalTokens > 0
                    text: (amc.msgInTokens && amc.msgOutTokens)
                        ? amc.msgInTokens + "→" + amc.msgOutTokens + " tok"
                        : amc.msgTotalTokens + " tok"
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall - 1
                    opacity: 0.8
                }
            }
        }
    }

    // ── Thinking Message ───────────────────────────────────────
    Component {
        id: thinkingMsgComponent

        Item {
            id: tmc
            width: parent.width
            readonly property var msg: parent ? parent.msg : null
            readonly property string contentText: msg ? (msg.content || "") : ""
            height: thinkingRow.height + Theme.spacingXS

            Row {
                id: thinkingRow
                anchors.left: parent.left
                spacing: Theme.spacingXS

                DankIcon {
                    name: "psychology"
                    size: 14
                    color: Theme.surfaceTextMedium
                    opacity: 0.6
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: tmc.contentText.length > 200
                          ? tmc.contentText.substring(0, 200) + "…"
                          : tmc.contentText
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    font.italic: true
                    wrapMode: Text.WordWrap
                    width: root.width - 50
                }
            }
        }
    }

    // ── Tool Call ──────────────────────────────────────────────
    Component {
        id: toolCallMsgComponent

        Item {
            id: tcc
            width: parent.width
            readonly property var msg: parent ? parent.msg : null
            readonly property string toolName: msg ? (msg.tool || "") : ""
            readonly property string toolPreview: msg ? (msg.toolPreview || "") : ""
            readonly property string toolStatus: msg ? (msg.toolStatus || "") : ""
            readonly property real toolDuration: msg ? (msg.toolDuration || 0) : 0
            height: toolRow.height + Theme.spacingXS

            Row {
                id: toolRow
                anchors.left: parent.left
                spacing: Theme.spacingXS

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: {
                        if (tcc.toolStatus === "running") return Theme.tertiary
                        if (tcc.toolStatus === "error") return Theme.error
                        return Theme.primary
                    }
                    anchors.verticalCenter: parent.verticalCenter

                    SequentialAnimation on opacity {
                        running: tcc.toolStatus === "running"
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.3; duration: 600 }
                        NumberAnimation { from: 0.3; to: 1; duration: 600 }
                    }
                }

                DankIcon {
                    name: "build"
                    size: 14
                    color: Theme.surfaceTextMedium
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: tcc.toolName
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    font.italic: true
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    visible: tcc.toolPreview !== ""
                    text: tcc.toolPreview.length > 80
                          ? tcc.toolPreview.substring(0, 80) + "…"
                          : tcc.toolPreview
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    font.italic: true
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, root.width * 0.5)
                    elide: Text.ElideRight
                }

                StyledText {
                    visible: tcc.toolStatus === "completed" || tcc.toolStatus === "error"
                    text: tcc.toolDuration > 0
                          ? (tcc.toolDuration < 1 ? (tcc.toolDuration * 1000).toFixed(0) + "ms" : tcc.toolDuration.toFixed(1) + "s")
                          : "✓"
                    color: tcc.toolStatus === "error" ? Theme.error : Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // ── Tool Result (collapsible) ──────────────────────────────
    Component {
        id: toolResultMsgComponent

        Item {
            id: trc
            width: parent.width
            readonly property var msg: parent ? parent.msg : null
            readonly property string toolName: msg ? (msg.tool || "") : ""
            readonly property string contentText: msg ? (msg.content || "") : ""
            readonly property bool isExpanded: msg ? !!msg.expanded : false
            height: trcCol.height

            Column {
                id: trcCol
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 4

                Rectangle {
                    width: parent.width
                    height: 22
                    color: trcHeaderMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    radius: 11

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: trc.isExpanded ? "expand_more" : "chevron_right"
                            size: 14
                            color: Theme.surfaceTextMedium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DankIcon {
                            name: "data_object"
                            size: 12
                            color: Theme.surfaceTextMedium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: (trc.toolName || "tool") + " output"
                            color: Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeSmall - 1
                            font.italic: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: " · " + trc.contentText.split("\n").length + " lines"
                            color: Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeSmall - 1
                            opacity: 0.7
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: trcHeaderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const ml = hermesService.messageList
                            for (let i = 0; i < ml.count; i++) {
                                if (ml.get(i).timestamp === trc.msg.timestamp
                                    && ml.get(i).type === "tool_result") {
                                    ml.setProperty(i, "expanded", !trc.isExpanded)
                                    break
                                }
                            }
                        }
                    }
                }

                CodeBlock {
                    visible: trc.isExpanded
                    width: parent.width * 0.92
                    content: visible ? trc.contentText : ""
                    language: "json"
                    complete: true
                }
            }
        }
    }

    // ── Approval Message ───────────────────────────────────────
    Component {
        id: approvalMsgComponent

        Item {
            id: apc
            width: parent.width
            readonly property var msg: parent ? parent.msg : null
            readonly property string contentText: msg ? (msg.content || "") : ""
            readonly property string toolStatus: msg ? (msg.toolStatus || "") : ""
            height: approvalCol.height + Theme.spacingS

            Column {
                id: approvalCol
                anchors.left: parent.left
                width: parent.width
                spacing: Theme.spacingXS

                Row {
                    spacing: Theme.spacingXS

                    DankIcon {
                        name: "shield"
                        size: 16
                        color: Theme.tertiary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Approval Required"
                        color: Theme.tertiary
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: parent.width
                    height: approvalContent.implicitHeight + Theme.spacingS * 2
                    color: Theme.surfaceVariantAlpha
                    radius: Theme.cornerRadius

                    StyledText {
                        id: approvalContent
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        text: apc.contentText
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: "monospace"
                        wrapMode: Text.WordWrap
                    }
                }

                Row {
                    visible: apc.toolStatus === ""
                    spacing: Theme.spacingXS

                    Rectangle {
                        width: approveBtnText.implicitWidth + Theme.spacingM * 2
                        height: 28
                        color: Theme.primary
                        radius: Math.max(4, Theme.cornerRadius / 2)

                        StyledText {
                            id: approveBtnText
                            anchors.centerIn: parent
                            text: "Allow Once"
                            color: Theme.onPrimary
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: hermesService.resolveApproval("once")
                        }
                    }

                    Rectangle {
                        width: sessionBtnText.implicitWidth + Theme.spacingM * 2
                        height: 28
                        color: Theme.surfaceVariantAlpha
                        radius: Math.max(4, Theme.cornerRadius / 2)

                        StyledText {
                            id: sessionBtnText
                            anchors.centerIn: parent
                            text: "Allow Session"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: hermesService.resolveApproval("session")
                        }
                    }

                    Rectangle {
                        width: denyBtnText.implicitWidth + Theme.spacingM * 2
                        height: 28
                        color: Theme.errorPressed
                        radius: Math.max(4, Theme.cornerRadius / 2)

                        StyledText {
                            id: denyBtnText
                            anchors.centerIn: parent
                            text: "Deny"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: hermesService.resolveApproval("deny")
                        }
                    }
                }

                StyledText {
                    visible: apc.toolStatus !== ""
                    text: apc.toolStatus === "once" || apc.toolStatus === "session"
                          ? "✓ Approved (" + apc.toolStatus + ")"
                          : apc.toolStatus === "always"
                            ? "✓ Always approved"
                            : "✗ Denied"
                    color: (apc.toolStatus === "deny") ? Theme.error : Theme.primary
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }
    }
}

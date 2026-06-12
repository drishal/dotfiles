import QtQuick
import qs.Common
import qs.Widgets
import "../services/toolFormat.js" as Tf

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
        messageListView.autoFollow = true
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
        messageListView.autoFollow = true
    }

    // Retry: resend the user message that preceded this assistant reply,
    // dropping everything from that point so a fresh response streams in.
    function retryMessage(assistantIndex) {
        if (hermesService.isRunning) return
        const ml = hermesService.messageList
        for (let i = assistantIndex - 1; i >= 0; i--) {
            if (ml.get(i).type === "user") {
                hermesService.resendFrom(i, ml.get(i).content)
                messageListView.autoFollow = true
                return
            }
        }
    }

    // Edit: pull a user message back into the input and truncate the
    // conversation to before it, so the next send resumes from there.
    function editMessage(userIndex, text) {
        if (hermesService.isRunning) return
        hermesService.truncateTo(userIndex)
        chatInput.text = text
        chatInput.forceActiveFocus()
        chatInput.cursorPosition = text.length
        messageListView.autoFollow = true
    }

    function tryPasteImage() {
        // Pulls a PNG off the Qt clipboard into /tmp and returns its path, or
        // "" when the clipboard holds no image (the normal text-paste case).
        const path = Platform.pasteImage()
        if (!path) return
        const name = path.split("/").pop()
        root.attachedImages = root.attachedImages.concat([{ path: path, name: name }])
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

            // Pin to the newest content while the user is reading near the
            // bottom; release the pin when they scroll up to read back, so
            // streaming tokens follow smoothly without yanking the view.
            property bool autoFollow: true
            property bool _pinning: false
            // Coalesced, re-entrancy-guarded pin. Calling positionViewAtEnd()
            // instantiates bottom delegates, which changes contentHeight — so
            // doing it directly from onContentHeightChanged loops forever (CPU
            // pegs, UI freezes) when variable-height rows like code blocks load.
            function _pinBottom() {
                if (!autoFollow || _pinning) return
                _pinning = true
                positionViewAtEnd()
                _pinning = false
            }
            onCountChanged: if (autoFollow) Qt.callLater(_pinBottom)
            // Follow growing content only while a reply is streaming (monotonic,
            // stable); a session load just pins once via onCountChanged.
            onContentHeightChanged: if (autoFollow && hermesService.isRunning) Qt.callLater(_pinBottom)
            onMovementEnded: autoFollow = atYEnd
            onFlickEnded: autoFollow = atYEnd

            // A window resize re-wraps every delegate (text reflows, tables
            // re-measure) and ListView's cached row positions go stale — rows
            // overlap until something forces a relayout. Coalesce one
            // forceLayout() per event-loop turn (so a continuous drag stays
            // tidy frame to frame), then restore the bottom pin.
            function _resettle() {
                forceLayout()
                if (autoFollow) _pinBottom()
            }
            onWidthChanged: Qt.callLater(_resettle)
            onHeightChanged: Qt.callLater(_resettle)

            // After a session load, delegate heights have just settled (rich
            // text, tables) — relayout once and pin to the latest message,
            // same as what a manual window resize was fixing by accident.
            // Run completion gets the same treatment: the streamed reply
            // re-segments from plain text into markdown/tables/code blocks,
            // so row heights jump and cached positions go stale.
            Connections {
                target: root.hermesService
                ignoreUnknownSignals: true
                function onMessagesLoaded() {
                    messageListView.autoFollow = true
                    Qt.callLater(messageListView._resettle)
                }
                function onRunCompleted(output) {
                    Qt.callLater(messageListView._resettle)
                }
                function onRunFailed(error) {
                    Qt.callLater(messageListView._resettle)
                }
            }

            // New rows fade in — but ONLY during a live run. Two traps avoided:
            //  • `bulkLoading` is too short-lived to gate on: ListView creates
            //    delegates lazily, after the append loop (and the flag) have
            //    finished, so the transition still fired on session loads. An
            //    in-flight add transition desyncs a row whose height then
            //    settles async (markdown/table re-measure) → rows overlap, and
            //    ListView never corrects it. Gating on isRunning keeps loads
            //    completely static.
            //  • No `displaced` transition at all — animating neighbour y has
            //    the same settle-desync problem. Neighbours snap to final y.
            add: Transition {
                enabled: root.hermesService.isRunning && !root.hermesService.bulkLoading
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 240; easing.type: Easing.OutBack }
            }

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
                objectName: "msgRow"
                width: messageListView.width - messageListView.leftMargin - messageListView.rightMargin
                height: contentLoader.height + Theme.spacingXS
                // Row heights settle asynchronously (MessageContent stacks its
                // segments via a coalesced relayout), so any late growth must
                // reposition the rows below — otherwise they overlap. Coalesced:
                // many rows changing in one turn still cost one forceLayout.
                onHeightChanged: Qt.callLater(messageListView._resettle)

                Loader {
                    id: contentLoader
                    width: parent.width
                    // Capture row data here — Components are declared outside the
                    // delegate, so they don't inherit the delegate's `model` context.
                    // Each loaded item reaches the row via `parent.msg` / `parent.msgIndex`.
                    property var msg: model
                    property int msgIndex: index
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

            WelcomeDashboard {
                visible: messageListView.count === 0
                anchors.fill: parent
                hermesService: root.hermesService
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

                    Behavior on color { ColorAnimation { duration: 300 } }

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

                Behavior on color { ColorAnimation { duration: 160 } }

                // Expanding "ping" ring while a run is active.
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: height / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.error
                    visible: hermesService.isRunning
                    z: -1
                    SequentialAnimation on opacity {
                        running: hermesService.isRunning
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.55; to: 0; duration: 1000; easing.type: Easing.OutCubic }
                    }
                    SequentialAnimation on scale {
                        running: hermesService.isRunning
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.85; to: 1.5; duration: 1000; easing.type: Easing.OutCubic }
                    }
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
            readonly property int rowIndex: parent ? parent.msgIndex : -1
            readonly property string contentText: msg ? (msg.content || "") : ""
            height: userBubble.height + (msgTime.visible ? msgTime.implicitHeight + 4 : 0) + 2

            HoverHandler { id: umcHover }

            // Hover toolbar in the empty space left of the user bubble: copy / edit.
            Rectangle {
                anchors.right: userBubble.left
                anchors.top: userBubble.top
                anchors.rightMargin: Theme.spacingXS
                width: umcActions.width + 6
                height: 22
                radius: 11
                color: Theme.surfaceContainerHighest
                border.width: 1
                border.color: Theme.outlineVariant
                opacity: (umcHover.hovered && !hermesService.isRunning) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 120 } }

                Row {
                    id: umcActions
                    anchors.centerIn: parent
                    spacing: 0

                    Rectangle {
                        width: 24; height: 18; radius: 6
                        color: copyUserMouse.containsMouse ? Theme.surfaceHover : "transparent"
                        DankIcon { anchors.centerIn: parent; name: "content_copy"; size: 13; color: Theme.surfaceTextMedium }
                        MouseArea {
                            id: copyUserMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Platform.copyToClipboard(umc.contentText)
                        }
                    }
                    Rectangle {
                        width: 24; height: 18; radius: 6
                        color: editUserMouse.containsMouse ? Theme.surfaceHover : "transparent"
                        DankIcon { anchors.centerIn: parent; name: "edit"; size: 13; color: Theme.surfaceTextMedium }
                        MouseArea {
                            id: editUserMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.editMessage(umc.rowIndex, umc.contentText)
                        }
                    }
                }
            }

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
            readonly property int rowIndex: parent ? parent.msgIndex : -1
            readonly property bool streaming: msg ? !!msg.isStreaming : false
            readonly property string contentText: msg ? (msg.content || "") : ""
            readonly property bool hasContent: contentText.length > 0
            readonly property real msgDuration: msg ? (msg.duration || 0) : 0
            readonly property int msgTotalTokens: msg && msg.usage ? (msg.usage.total_tokens || 0) : 0
            readonly property int msgInTokens: msg && msg.usage ? (msg.usage.input_tokens || 0) : 0
            readonly property int msgOutTokens: msg && msg.usage ? (msg.usage.output_tokens || 0) : 0
            readonly property bool hasStats: !streaming && (msgDuration > 0 || msgTotalTokens > 0)
            height: assistantBubble.height
                    + (msgTime.visible ? msgTime.implicitHeight + 2 : 0)
                    + (statsRow.visible ? statsRow.implicitHeight + 1 : 0)
                    + 2

            // Claude-style: assistant text flows directly on the background —
            // no bubble, full measure.
            Item {
                id: assistantBubble
                anchors.left: parent.left
                width: parent.width
                height: bubbleContent.implicitHeight + Theme.spacingXS + (amc.streaming ? 4 : 0)

                Item {
                    id: bubbleContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 2
                    implicitHeight: amc.streaming && !amc.hasContent
                        ? thinkingIndicator.height
                        : messageContent.implicitHeight + (amc.streaming ? cursorDot.height + 2 : 0)

                    Row {
                        id: thinkingIndicator
                        visible: amc.streaming && !amc.hasContent
                        spacing: Theme.spacingXS
                        anchors.left: parent.left

                        // Whole row breathes while we wait for the first token.
                        SequentialAnimation on opacity {
                            running: thinkingIndicator.visible
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.5; to: 1; duration: 750; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1; to: 0.5; duration: 750; easing.type: Easing.InOutSine }
                        }

                        DankIcon {
                            name: "auto_awesome"
                            size: 14
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

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

            HoverHandler { id: amcHover }

            // Hover toolbar: copy / retry.
            Rectangle {
                anchors.right: assistantBubble.right
                anchors.top: assistantBubble.top
                anchors.margins: 4
                width: amcActions.width + 6
                height: 22
                radius: 11
                color: Theme.surfaceContainerHighest
                border.width: 1
                border.color: Theme.outlineVariant
                opacity: (amcHover.hovered && !amc.streaming && amc.hasContent) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 120 } }

                Row {
                    id: amcActions
                    anchors.centerIn: parent
                    spacing: 0

                    Rectangle {
                        width: 24; height: 18; radius: 6
                        color: copyAsstMouse.containsMouse ? Theme.surfaceHover : "transparent"
                        DankIcon { anchors.centerIn: parent; name: "content_copy"; size: 13; color: Theme.surfaceTextMedium }
                        MouseArea {
                            id: copyAsstMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Platform.copyToClipboard(amc.contentText)
                        }
                    }
                    Rectangle {
                        width: 24; height: 18; radius: 6
                        opacity: hermesService.isRunning ? 0.4 : 1
                        color: retryAsstMouse.containsMouse ? Theme.surfaceHover : "transparent"
                        DankIcon { anchors.centerIn: parent; name: "refresh"; size: 13; color: Theme.surfaceTextMedium }
                        MouseArea {
                            id: retryAsstMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.retryMessage(amc.rowIndex)
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

    // ── Thinking (collapsible reasoning card, webui-style) ─────
    // Mirrors hermes-webui's thinking card: a primary-tinted disclosure row
    // with a lightbulb + "Thinking" label, copy button and rotating chevron;
    // the body holds the full reasoning trace in small muted monospace,
    // scrollable past ~260px. Collapsed by default, including while the
    // reasoning is still streaming into it.
    Component {
        id: thinkingMsgComponent

        Item {
            id: tmc
            width: parent.width
            readonly property var msg: parent ? parent.msg : null
            readonly property int rowIndex: parent ? parent.msgIndex : -1
            readonly property string contentText: msg ? (msg.content || "") : ""
            readonly property bool isExpanded: msg ? !!msg.expanded : false
            // The reasoning is streaming in right now: this is the newest row
            // and a run is active. Auto-open so the trace is visible live (the
            // webui shows reasoning as it streams), without forcing the
            // persisted `expanded` state. Once the answer starts (a newer row
            // appears) or the run ends, it falls back to the user's choice.
            readonly property bool isLive: hermesService.isRunning
                                           && rowIndex === hermesService.messageList.count - 1
            readonly property bool showBody: isExpanded || isLive
            height: thinkCard.height + 2

            function toggleExpanded() {
                const ml = hermesService.messageList
                if (rowIndex >= 0 && rowIndex < ml.count)
                    ml.setProperty(rowIndex, "expanded", !isExpanded)
            }

            Rectangle {
                id: thinkCard
                anchors.left: parent.left
                anchors.right: parent.right
                height: 26 + (tmc.showBody ? thinkBody.height : 0)
                radius: Math.max(6, Theme.cornerRadius / 2)
                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.06)
                border.width: 1
                border.color: thinkMouse.containsMouse
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
                    : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
                Behavior on border.color { ColorAnimation { duration: 120 } }
                Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                Item {
                    id: thinkHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 26

                    MouseArea {
                        id: thinkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tmc.toggleExpanded()
                    }

                    DankIcon {
                        id: thinkBulb
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        name: "lightbulb"
                        size: 13
                        color: Theme.primary
                        opacity: 0.7
                    }

                    StyledText {
                        id: thinkLabel
                        anchors.left: thinkBulb.right
                        anchors.leftMargin: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter
                        text: tmc.isLive ? "Thinking…" : "Thinking"
                        color: Theme.primary
                        opacity: thinkMouse.containsMouse ? 1 : 0.85
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold

                        // Gentle pulse while the reasoning streams.
                        SequentialAnimation on opacity {
                            running: tmc.isLive
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.55; to: 1; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1; to: 0.55; duration: 700; easing.type: Easing.InOutSine }
                        }
                    }

                    DankIcon {
                        id: thinkChevron
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        name: "chevron_right"
                        size: 13
                        color: Theme.primary
                        opacity: 0.7
                        rotation: tmc.showBody ? 90 : 0
                        Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    // Copy the full trace (declared after thinkMouse so it
                    // stays on top and clickable).
                    Rectangle {
                        anchors.right: thinkChevron.left
                        anchors.rightMargin: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 18
                        radius: 6
                        color: thinkCopyMouse.containsMouse ? Theme.surfaceHover : "transparent"

                        DankIcon {
                            anchors.centerIn: parent
                            name: "content_copy"
                            size: 11
                            color: Theme.primary
                            opacity: 0.8
                        }

                        MouseArea {
                            id: thinkCopyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Platform.copyToClipboard(tmc.contentText)
                        }
                    }
                }

                Item {
                    id: thinkBody
                    visible: tmc.showBody
                    anchors.top: thinkHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Math.min(thinkText.implicitHeight + Theme.spacingS, 260)

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
                    }

                    Flickable {
                        id: thinkFlick
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingS
                        anchors.rightMargin: Theme.spacingS
                        anchors.topMargin: Theme.spacingXS
                        anchors.bottomMargin: Theme.spacingXS
                        contentWidth: width
                        contentHeight: thinkText.implicitHeight
                        clip: true
                        flickableDirection: Flickable.VerticalFlick
                        interactive: contentHeight > height
                        boundsBehavior: Flickable.StopAtBounds

                        // Keep the newest reasoning in view while it streams.
                        onContentHeightChanged: if (tmc.isLive) contentY = Math.max(0, contentHeight - height)

                        TextEdit {
                            id: thinkText
                            width: parent.width
                            text: tmc.contentText
                            color: Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeSmall - 1
                            font.family: "monospace"
                            wrapMode: TextEdit.Wrap
                            textFormat: TextEdit.PlainText
                            readOnly: true
                            selectByMouse: true
                            selectionColor: Theme.primary
                            selectedTextColor: Theme.onPrimary
                            HoverHandler {
                                cursorShape: Qt.IBeamCursor
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Tool Call ──────────────────────────────────────────────
    // Claude-style activity card: icon · tool name · muted one-line preview,
    // status on the right, click to expand the full arguments.
    Component {
        id: toolCallMsgComponent

        Item {
            id: tcc
            width: parent.width
            readonly property var msg: parent ? parent.msg : null
            readonly property int rowIndex: parent ? parent.msgIndex : -1
            readonly property string toolName: msg ? (msg.tool || "") : ""
            readonly property string toolPreview: msg ? (msg.toolPreview || "") : ""
            readonly property string toolStatus: msg ? (msg.toolStatus || "") : ""
            readonly property real toolDuration: msg ? (msg.toolDuration || 0) : 0
            readonly property bool isExpanded: msg ? !!msg.expanded : false
            readonly property string previewLine: toolPreview.replace(/\s+/g, " ").trim()
            height: card.height + 2

            function toggleExpanded() {
                if (!previewLine) return
                const ml = hermesService.messageList
                if (rowIndex >= 0 && rowIndex < ml.count)
                    ml.setProperty(rowIndex, "expanded", !isExpanded)
            }

            Rectangle {
                id: card
                anchors.left: parent.left
                anchors.right: parent.right
                // Explicit height: a positioner's implicitHeight doesn't settle
                // inside the delegate Loader chain (sticks at 0 — collapsed
                // cards, overlapping rows), so don't lean on a Column here.
                height: 30 + (tcc.isExpanded ? argsBox.height : 0)
                radius: Math.max(6, Theme.cornerRadius / 2)
                color: Theme.surfaceContainer
                border.width: 1
                border.color: headerMouse.containsMouse ? Theme.outlineMedium : Theme.outlineVariant
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Item {
                    id: callHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 30

                    DankIcon {
                        id: toolIcon
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            name: Tf.iconFor(tcc.toolName)
                            size: 14
                            color: tcc.toolStatus === "error" ? Theme.error : Theme.surfaceTextMedium
                        }

                        StyledText {
                            id: toolNameText
                            anchors.left: toolIcon.right
                            anchors.leftMargin: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter
                            text: tcc.toolName
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                        }

                        // Far right: expand chevron when there's anything to show.
                        DankIcon {
                            id: chevron
                            visible: tcc.previewLine.length > 0
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            name: tcc.isExpanded ? "expand_less" : "expand_more"
                            size: 14
                            color: Theme.surfaceTextMedium
                        }

                        // Status: spinner while running, then duration / failed.
                        DankIcon {
                            id: statusIcon
                            anchors.right: chevron.visible ? chevron.left : parent.right
                            anchors.rightMargin: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter
                            visible: tcc.toolStatus !== ""
                            name: tcc.toolStatus === "running" ? "progress_activity"
                                : tcc.toolStatus === "error" ? "error_outline" : "check"
                            size: 13
                            color: tcc.toolStatus === "error" ? Theme.error
                                 : tcc.toolStatus === "running" ? Theme.tertiary
                                 : Theme.surfaceTextMedium

                            RotationAnimation on rotation {
                                running: tcc.toolStatus === "running"
                                loops: Animation.Infinite
                                from: 0; to: 360
                                duration: 900
                            }
                            // Reset the spin once the call resolves.
                            Connections {
                                target: tcc
                                function onToolStatusChanged() {
                                    if (tcc.toolStatus !== "running") statusIcon.rotation = 0
                                }
                            }
                        }

                        StyledText {
                            id: statusText
                            anchors.right: statusIcon.visible ? statusIcon.left : parent.right
                            anchors.rightMargin: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter
                            visible: text !== ""
                            text: {
                                if (tcc.toolStatus === "running") return "running…"
                                if (tcc.toolStatus === "error") return "failed"
                                if (tcc.toolDuration > 0) {
                                    return tcc.toolDuration < 1
                                        ? (tcc.toolDuration * 1000).toFixed(0) + "ms"
                                        : tcc.toolDuration.toFixed(1) + "s"
                                }
                                return ""
                            }
                            color: tcc.toolStatus === "error" ? Theme.error : Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeSmall - 1
                            font.italic: tcc.toolStatus === "running"
                        }

                        // Muted one-line preview between the name and the status.
                        StyledText {
                            visible: !tcc.isExpanded && tcc.previewLine.length > 0
                            anchors.left: toolNameText.right
                            anchors.leftMargin: Theme.spacingM
                            anchors.right: statusText.visible ? statusText.left
                                         : statusIcon.visible ? statusIcon.left
                                         : chevron.visible ? chevron.left : parent.right
                            anchors.rightMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            text: tcc.previewLine
                            color: Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeSmall - 1
                            font.family: "monospace"
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: headerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: tcc.previewLine ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: tcc.toggleExpanded()
                        }
                    }

                // Expanded: the arguments as a neat tree.
                Item {
                    id: argsBox
                    visible: tcc.isExpanded
                    anchors.top: callHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Math.min(argsJson.height, 320) + Theme.spacingS

                    Flickable {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingS + 22
                        anchors.rightMargin: Theme.spacingS
                        contentWidth: width
                        contentHeight: argsJson.height
                        clip: true
                        flickableDirection: Flickable.VerticalFlick
                        interactive: contentHeight > height
                        boundsBehavior: Flickable.StopAtBounds

                        JsonView {
                            id: argsJson
                            width: parent.width
                            content: tcc.isExpanded ? tcc.toolPreview : ""
                        }
                    }
                }
            }
        }
    }

    // ── Tool Result (collapsible card) ─────────────────────────
    Component {
        id: toolResultMsgComponent

        Item {
            id: trc
            width: parent.width
            readonly property var msg: parent ? parent.msg : null
            readonly property int rowIndex: parent ? parent.msgIndex : -1
            readonly property string toolName: msg ? (msg.tool || "") : ""
            readonly property string contentText: msg ? (msg.content || "") : ""
            readonly property bool isExpanded: msg ? !!msg.expanded : false
            readonly property var _summary: Tf.summarizeResult(toolName, contentText)
            readonly property bool success: !_summary || _summary.success !== false
            height: card.height + 2

            Rectangle {
                id: card
                anchors.left: parent.left
                anchors.right: parent.right
                // Explicit height — see the tool-call card for why no Column.
                height: 30 + (trc.isExpanded ? resBox.height : 0)
                radius: Math.max(6, Theme.cornerRadius / 2)
                color: Theme.surfaceContainer
                border.width: 1
                border.color: trcHeaderMouse.containsMouse ? Theme.outlineMedium : Theme.outlineVariant
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Item {
                    id: resHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 30

                    DankIcon {
                        id: resStateIcon
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            name: trc.success ? "check_circle" : "error_outline"
                            size: 13
                            color: trc.success ? Theme.surfaceTextMedium : Theme.error
                        }

                        StyledText {
                            id: resName
                            anchors.left: resStateIcon.right
                            anchors.leftMargin: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter
                            text: trc.toolName || "result"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                        }

                        DankIcon {
                            id: resChevron
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            name: trc.isExpanded ? "expand_less" : "expand_more"
                            size: 14
                            color: Theme.surfaceTextMedium
                        }

                        StyledText {
                            id: resLines
                            anchors.right: resChevron.left
                            anchors.rightMargin: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter
                            text: trc.contentText.split("\n").length + " lines"
                            color: Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeSmall - 2
                            opacity: 0.7
                        }

                        // Muted result summary between the name and the line count.
                        StyledText {
                            visible: !trc.isExpanded && trc._summary && !!trc._summary.detail
                            anchors.left: resName.right
                            anchors.leftMargin: Theme.spacingM
                            anchors.right: resLines.left
                            anchors.rightMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            text: trc._summary ? (trc._summary.detail || "") : ""
                            color: Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeSmall - 1
                            font.family: "monospace"
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: trcHeaderMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const ml = hermesService.messageList
                                if (trc.rowIndex >= 0 && trc.rowIndex < ml.count)
                                    ml.setProperty(trc.rowIndex, "expanded", !trc.isExpanded)
                            }
                        }
                    }

                Item {
                    id: resBox
                    visible: trc.isExpanded
                    anchors.top: resHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    // Cap very large payloads (e.g. web_search's 40+ lines) and
                    // let the body scroll, like the old CodeBlock did.
                    height: Math.min(resultJson.height, 320) + Theme.spacingS

                    Flickable {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingS + 22
                        anchors.rightMargin: Theme.spacingS
                        anchors.topMargin: Theme.spacingXS
                        contentWidth: width
                        contentHeight: resultJson.height
                        clip: true
                        flickableDirection: Flickable.VerticalFlick
                        interactive: contentHeight > height
                        boundsBehavior: Flickable.StopAtBounds

                        JsonView {
                            id: resultJson
                            width: parent.width
                            content: trc.isExpanded ? trc.contentText : ""
                            sourceAccent: trc.success ? Theme.primary : Theme.error
                        }
                    }
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
            readonly property bool resolved: toolStatus !== ""
            readonly property bool denied: toolStatus === "deny"
            readonly property color accent: resolved ? (denied ? Theme.error : Theme.primary) : Theme.tertiary
            height: approvalCard.height + Theme.spacingS

            Rectangle {
                id: approvalCard
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: parent.width * 0.06
                height: approvalCol.implicitHeight + Theme.spacingM * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                border.width: 1
                border.color: apc.accent
                Behavior on border.color { ColorAnimation { duration: 220 } }

                // Attention accent bar down the left edge.
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    width: 3
                    radius: 1.5
                    color: apc.accent
                    Behavior on color { ColorAnimation { duration: 220 } }
                }

                Column {
                    id: approvalCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: Theme.spacingM
                    anchors.rightMargin: Theme.spacingM
                    anchors.topMargin: Theme.spacingM
                    spacing: Theme.spacingS

                    Row {
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: apc.resolved ? (apc.denied ? "block" : "verified_user") : "admin_panel_settings"
                            size: 16
                            color: apc.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "Permission required"
                            color: apc.accent
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Highlighted, copyable command preview.
                    CodeBlock {
                        width: parent.width
                        content: apc.contentText
                        language: "bash"
                        complete: true
                    }

                    // Action buttons.
                    Row {
                        visible: !apc.resolved
                        spacing: Theme.spacingXS

                        Rectangle {
                            width: allowOnceRow.implicitWidth + Theme.spacingM * 2
                            height: 30
                            radius: Math.max(4, Theme.cornerRadius / 2)
                            color: allowOnceMouse.containsMouse ? Theme.primaryPressed : Theme.primary
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                id: allowOnceRow
                                anchors.centerIn: parent
                                spacing: 4
                                DankIcon { name: "check"; size: 14; color: Theme.onPrimary; anchors.verticalCenter: parent.verticalCenter }
                                StyledText { text: "Allow once"; color: Theme.onPrimary; font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                            }

                            MouseArea {
                                id: allowOnceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: hermesService.resolveApproval("once")
                            }
                        }

                        Rectangle {
                            width: allowSessionRow.implicitWidth + Theme.spacingM * 2
                            height: 30
                            radius: Math.max(4, Theme.cornerRadius / 2)
                            color: allowSessionMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceVariantAlpha
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                id: allowSessionRow
                                anchors.centerIn: parent
                                spacing: 4
                                DankIcon { name: "schedule"; size: 14; color: Theme.surfaceText; anchors.verticalCenter: parent.verticalCenter }
                                StyledText { text: "Allow session"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
                            }

                            MouseArea {
                                id: allowSessionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: hermesService.resolveApproval("session")
                            }
                        }

                        Rectangle {
                            width: denyRow.implicitWidth + Theme.spacingM * 2
                            height: 30
                            radius: Math.max(4, Theme.cornerRadius / 2)
                            color: denyMouse.containsMouse ? Theme.error : Theme.errorPressed
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                id: denyRow
                                anchors.centerIn: parent
                                spacing: 4
                                DankIcon { name: "block"; size: 14; color: denyMouse.containsMouse ? Theme.onPrimary : Theme.error; anchors.verticalCenter: parent.verticalCenter }
                                StyledText { text: "Deny"; color: denyMouse.containsMouse ? Theme.onPrimary : Theme.error; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
                            }

                            MouseArea {
                                id: denyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: hermesService.resolveApproval("deny")
                            }
                        }
                    }

                    // Resolved status.
                    Row {
                        visible: apc.resolved
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: apc.denied ? "cancel" : "check_circle"
                            size: 14
                            color: apc.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: apc.toolStatus === "once" || apc.toolStatus === "session"
                                  ? "Approved (" + apc.toolStatus + ")"
                                  : apc.toolStatus === "always" ? "Always approved" : "Denied"
                            color: apc.accent
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}

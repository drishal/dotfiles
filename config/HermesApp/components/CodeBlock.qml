import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string content: ""
    property string language: ""
    property bool complete: true

    implicitHeight: contentCol.implicitHeight + Theme.spacingS * 2
    height: implicitHeight
    color: Theme.surfaceContainerHighest
    radius: Math.max(4, Theme.cornerRadius / 2)
    border.width: 1
    border.color: Theme.outlineVariant
    clip: true

    // Cached chroma output (HTML with inline styles). Empty = fall back to plain.
    property string _highlightedHtml: ""

    // Convert a QML color to a CSS hex string Qt RichText accepts.
    // Theme tokens with alpha (e.g. surfaceTextMedium) come back as #aarrggbb;
    // drop the alpha so we always emit #rrggbb.
    function _hex(c) {
        const s = (c !== undefined && c !== null) ? c.toString() : ""
        if (s.length === 9 && s[0] === "#") return "#" + s.slice(3)
        return s
    }

    // Remap chroma's monokai palette to the current DMS theme tokens so the
    // code block follows the user's theme (and re-evaluates when it changes).
    readonly property string _themedHtml: {
        let html = root._highlightedHtml
        if (!html) return ""
        // Strip chroma's outer <pre style="..."> — we provide our own surface.
        html = html.replace(/<pre[^>]*>/i, "<pre>")
        const map = {
            "#f8f8f2": _hex(Theme.surfaceText),
            "#66d9ef": _hex(Theme.primary),
            "#a6e22e": _hex(Theme.tertiary),
            "#f92672": _hex(Theme.primary),
            "#e6db74": _hex(Theme.success),
            "#ae81ff": _hex(Theme.warning),
            "#75715e": _hex(Theme.surfaceVariantText)
        }
        for (const k in map) {
            if (map[k]) html = html.replace(new RegExp(k, "gi"), map[k])
        }
        return html
    }

    function refreshHighlight() {
        if (!root.complete || !root.content) {
            root._highlightedHtml = ""
            return
        }
        // Synchronous, in-process Pygments — returns monokai HTML the theme
        // remap below recolors. Empty string falls back to plain text.
        root._highlightedHtml = Platform.highlightHtml(root.content, root.language || "text")
    }

    onContentChanged: refreshHighlight()
    onLanguageChanged: refreshHighlight()
    onCompleteChanged: refreshHighlight()
    Component.onCompleted: refreshHighlight()

    // Stand-in for the old copy Process. Qt clipboard, no `dms` dependency.
    QtObject {
        id: copyProcess
        property bool justCopied: false
        function copy(s) {
            Platform.copyToClipboard(s)
            justCopied = true
            copyTimer.restart()
        }
    }

    Timer {
        id: copyTimer
        interval: 1500
        onTriggered: copyProcess.justCopied = false
    }

    Column {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Theme.spacingS
        anchors.rightMargin: Theme.spacingS
        anchors.topMargin: Theme.spacingS
        spacing: 4

        Item {
            width: parent.width
            height: 18

            StyledText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.language ? root.language : "code"
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall - 1
                font.italic: true
            }

            StyledText {
                anchors.right: copyButton.left
                anchors.rightMargin: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.complete
                text: "streaming…"
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall - 1
                font.italic: true
            }

            Rectangle {
                id: copyButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: copyLabel.implicitWidth + copyIcon.width + Theme.spacingXS * 3
                height: 18
                radius: 9
                color: copyMouse.containsMouse ? Theme.surfaceHover : "transparent"

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingXS

                    DankIcon {
                        id: copyIcon
                        name: copyProcess.justCopied ? "check" : "content_copy"
                        size: 12
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        id: copyLabel
                        text: copyProcess.justCopied ? "Copied" : "Copy"
                        color: Theme.primary
                        font.pixelSize: Theme.fontSizeSmall - 1
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: copyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: copyProcess.copy(root.content)
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outlineVariant
        }

        Flickable {
            width: parent.width
            height: codeText.implicitHeight
            contentWidth: Math.max(codeText.implicitWidth + Theme.spacingS * 2, width)
            contentHeight: codeText.implicitHeight
            clip: true
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            TextEdit {
                id: codeText
                textFormat: root._highlightedHtml ? TextEdit.RichText : TextEdit.PlainText
                text: root._themedHtml || root.content
                color: Theme.surfaceText
                font.family: "monospace"
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: TextEdit.NoWrap
                readOnly: true
                selectByMouse: true
                selectionColor: Theme.primary
                selectedTextColor: Theme.onPrimary
                persistentSelection: true
                HoverHandler {
                    cursorShape: Qt.IBeamCursor
                }
            }
        }
    }
}

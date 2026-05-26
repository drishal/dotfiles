import QtQuick
import Quickshell.Io
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

    Process {
        id: chromaProcess
        running: false
        property string code: ""
        property string lang: ""
        command: ["sh", "-c", "printf '%s' \"$CODE\" | dms chroma -l \"$LANG\" --inline 2>/dev/null"]
        environment: ({ "CODE": code, "LANG": lang || "text" })
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.length > 0) {
                    root._highlightedHtml = text
                }
            }
        }
    }

    function refreshHighlight() {
        if (!root.complete || !root.content) {
            root._highlightedHtml = ""
            return
        }
        chromaProcess.code = root.content
        chromaProcess.lang = root.language || "text"
        chromaProcess.running = true
    }

    onContentChanged: refreshHighlight()
    onLanguageChanged: refreshHighlight()
    onCompleteChanged: refreshHighlight()
    Component.onCompleted: refreshHighlight()

    Process {
        id: copyProcess
        running: false
        property string toCopy: ""
        property bool justCopied: false
        command: ["sh", "-c", "printf '%s' \"$CONTENT\" | dms clipboard copy"]
        environment: ({ "CONTENT": toCopy })
        onExited: (code, status) => {
            if (code === 0) {
                justCopied = true
                copyTimer.restart()
            }
        }
        function copy(s) {
            toCopy = s
            running = true
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

            Text {
                id: codeText
                textFormat: root._highlightedHtml ? Text.RichText : Text.PlainText
                text: root._highlightedHtml || root.content
                color: Theme.surfaceText
                font.family: "monospace"
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.NoWrap
            }
        }
    }
}

import QtQuick
import qs.Common
import qs.Widgets
import "../services/markdownSegments.js" as Md

Item {
    id: root

    property string text: ""
    property bool isStreaming: false

    // While streaming, fall back to a single plain-text segment so the renderer
    // doesn't churn delegates on every delta and unbalanced ``` fences don't
    // misrender. Once the run completes the full segmented view kicks in.
    readonly property var segments: root.isStreaming
        ? [{ type: "text", content: root.text || "", language: "", complete: false }]
        : Md.segment(root.text || "")

    implicitHeight: layout.implicitHeight
    height: implicitHeight

    Column {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.spacingXS

        Repeater {
            model: root.segments

            delegate: Item {
                width: layout.width
                height: Math.max(textSeg.visible ? textSeg.implicitHeight : 0,
                                 codeSeg.visible ? codeSeg.height : 0)

                property var seg: modelData

                TextEdit {
                    id: textSeg
                    visible: parent.seg && parent.seg.type === "text"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: visible ? parent.seg.content : ""
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    wrapMode: TextEdit.Wrap
                    textFormat: root.isStreaming ? TextEdit.PlainText : TextEdit.MarkdownText
                    readOnly: true
                    selectByMouse: true
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.onPrimary
                    persistentSelection: true
                    onLinkActivated: link => Qt.openUrlExternally(link)
                    HoverHandler {
                        cursorShape: textSeg.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
                    }
                }

                CodeBlock {
                    id: codeSeg
                    visible: parent.seg && parent.seg.type === "code"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    content: visible ? parent.seg.content : ""
                    language: visible ? parent.seg.language : ""
                    complete: visible ? !!parent.seg.complete : true
                }
            }
        }
    }
}

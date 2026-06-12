import QtQuick
import qs.Common
import qs.Widgets
import "../services/markdownSegments.js" as Md

// Renders assistant markdown as a stack of segments: text (MarkdownText),
// fenced code blocks (CodeBlock) and GFM tables (TableBlock).
//
// Segments are stacked manually (relayout() assigns each delegate's y and
// sums the total) instead of with a Column. QML positioners compute their
// geometry during polish, which proves unreliable inside the message
// delegate's Loader chain — children end up unpositioned (overlapping at
// y=0) or the positioner's implicit size sticks at a stale value, which is
// exactly the overlapping-message bug. Explicit math has no such failure
// mode: it re-runs (coalesced via Qt.callLater) whenever a segment's height
// or the count changes.
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

    property real _stackedHeight: 0
    implicitHeight: _stackedHeight
    height: implicitHeight

    function _relayout() {
        let y = 0
        let first = true
        for (let k = 0; k < segRepeater.count; k++) {
            const it = segRepeater.itemAt(k)
            if (!it || it.height <= 0) continue
            if (!first) y += Theme.spacingXS
            it.y = y
            y += it.height
            first = false
        }
        root._stackedHeight = y
    }

    onWidthChanged: Qt.callLater(_relayout)

    Repeater {
        id: segRepeater
        model: root.segments
        onItemAdded: Qt.callLater(root._relayout)
        onItemRemoved: Qt.callLater(root._relayout)

        delegate: Item {
            width: root.width
            height: Math.max(textSeg.visible ? textSeg.implicitHeight : 0,
                             codeSeg.visible ? codeSeg.height : 0,
                             tableSeg.visible ? tableSeg.height : 0)
            onHeightChanged: Qt.callLater(root._relayout)

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

            TableBlock {
                id: tableSeg
                visible: parent.seg && parent.seg.type === "table"
                anchors.left: parent.left
                anchors.right: parent.right
                headers: visible ? parent.seg.headers : []
                align: visible ? parent.seg.align : []
                rows: visible ? parent.seg.rows : []
                weights: visible ? parent.seg.weights : []
            }
        }
    }
}

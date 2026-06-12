import QtQuick
import qs.Common
import qs.Widgets
import "../services/jsonFormat.js" as Jf

// A neat, collapsible, syntax-coloured JSON tree — the structured alternative
// to dumping raw JSON. Falls back to plain monospace text when the payload
// isn't JSON. Rows are stacked manually (no positioners — they misbehave in
// the message delegate's Loader chain, see MessageContent).
Item {
    id: root

    // Raw payload (may include the <untrusted_tool_result> envelope).
    property string content: ""
    property color sourceAccent: Theme.primary

    readonly property var _unwrapped: Jf.unwrap(content)
    readonly property string source: _unwrapped.source
    readonly property var _parsed: Jf.tryParse(_unwrapped.body)
    readonly property bool isJson: _parsed.ok

    // Collapsed node paths (path → true). Mutated by node clicks.
    property var _collapsed: ({})
    readonly property var rows: isJson ? Jf.flatten(_parsed.value, _collapsed) : []

    property real _stackedHeight: 0
    implicitHeight: _stackedHeight
    height: implicitHeight

    readonly property int indentStep: 14
    readonly property int lineH: Math.round(Theme.fontSizeSmall * 1.55)

    function _toggle(path) {
        const c = {}
        for (const k in _collapsed) c[k] = _collapsed[k]
        c[path] = !c[path]
        _collapsed = c
    }

    function _colorFor(vtype) {
        switch (vtype) {
        case "string": return Theme.success
        case "number": return Theme.warning
        case "bool":   return Theme.tertiary
        case "null":   return Theme.surfaceVariantText
        default:       return Theme.surfaceText
        }
    }

    function _relayout() {
        let y = 0
        if (sourceChip.visible) y += sourceChip.height + Theme.spacingXS
        for (let k = 0; k < rowRepeater.count; k++) {
            const it = rowRepeater.itemAt(k)
            if (!it) continue
            it.y = y
            y += it.height
        }
        if (!isJson) y = Math.max(y, plainText.implicitHeight)
        root._stackedHeight = y
    }

    onWidthChanged: Qt.callLater(_relayout)
    onRowsChanged: Qt.callLater(_relayout)

    // ── External-source chip ────────────────────────────────────
    Rectangle {
        id: sourceChip
        visible: root.source.length > 0
        x: 0
        y: 0
        height: visible ? sourceLabel.implicitHeight + 6 : 0
        width: sourceLabel.implicitWidth + 18
        radius: height / 2
        color: Qt.rgba(root.sourceAccent.r, root.sourceAccent.g, root.sourceAccent.b, 0.12)

        Row {
            anchors.centerIn: parent
            spacing: 4
            DankIcon {
                name: "public"; size: 11
                color: root.sourceAccent
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                id: sourceLabel
                text: root.source
                color: root.sourceAccent
                font.pixelSize: Theme.fontSizeSmall - 2
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ── Plain-text fallback (non-JSON payloads) ─────────────────
    TextEdit {
        id: plainText
        visible: !root.isJson
        x: 0
        anchors.right: parent.right
        text: visible ? root._unwrapped.body : ""
        color: Theme.surfaceTextMedium
        font.pixelSize: Theme.fontSizeSmall
        font.family: "monospace"
        wrapMode: TextEdit.Wrap
        textFormat: TextEdit.PlainText
        readOnly: true
        selectByMouse: true
        selectionColor: Theme.primary
        selectedTextColor: Theme.onPrimary
        onImplicitHeightChanged: Qt.callLater(root._relayout)
    }

    // ── JSON rows ───────────────────────────────────────────────
    Repeater {
        id: rowRepeater
        model: root.isJson ? root.rows : []
        onItemAdded: Qt.callLater(root._relayout)
        onItemRemoved: Qt.callLater(root._relayout)

        delegate: Item {
            id: line
            property var row: modelData
            width: root.width
            height: lineContent.implicitHeight + 2
            onHeightChanged: Qt.callLater(root._relayout)

            // Hover affordance only on collapsible (open) rows.
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: -4
                radius: 4
                visible: line.row.kind === "open" && lineMouse.containsMouse
                color: Theme.surfaceHover
                opacity: 0.5
            }

            Row {
                id: lineContent
                x: (line.row.depth || 0) * root.indentStep
                spacing: 0

                // Collapse caret for container-open rows.
                DankIcon {
                    visible: line.row.kind === "open"
                    width: visible ? 14 : 0
                    name: line.row.collapsed ? "chevron_right" : "expand_more"
                    size: 13
                    color: Theme.surfaceTextMedium
                    anchors.verticalCenter: parent.verticalCenter
                }
                // Indent spacer keeping non-open rows aligned with open rows.
                Item {
                    visible: line.row.kind !== "open"
                    width: visible ? 14 : 0
                    height: 1
                }

                // key:
                StyledText {
                    visible: !!line.row.keyed
                    text: visible ? (jsonKey(line.row.key) + ": ") : ""
                    color: root.sourceAccent
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: "monospace"
                    anchors.verticalCenter: parent.verticalCenter
                    function jsonKey(k) { return k }
                }

                // value / bracket
                StyledText {
                    text: {
                        const r = line.row
                        if (r.kind === "scalar") return r.valueText + (r.comma ? "," : "")
                        if (r.kind === "empty")  return r.text + (r.comma ? "," : "")
                        if (r.kind === "open")
                            return r.collapsed
                                ? r.bracket + " " + r.summary + " " + r.close + (r.comma ? "," : "")
                                : r.bracket
                        if (r.kind === "close")  return r.bracket + (r.comma ? "," : "")
                        return ""
                    }
                    color: {
                        const r = line.row
                        if (r.kind === "scalar") return root._colorFor(r.valueType)
                        if (r.kind === "open" && r.collapsed) return Theme.surfaceTextMedium
                        return Theme.surfaceTextMedium
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: "monospace"
                    wrapMode: Text.WrapAnywhere
                    width: Math.min(implicitWidth, root.width - x - (line.row.depth || 0) * root.indentStep - 28)
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: lineMouse
                anchors.fill: parent
                hoverEnabled: line.row.kind === "open"
                enabled: line.row.kind === "open"
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root._toggle(line.row.path)
            }
        }
    }
}

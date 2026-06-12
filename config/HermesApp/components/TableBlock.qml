import QtQuick
import qs.Common
import qs.Widgets

// A properly padded table in the Claude style — transparent background,
// horizontal rules only, no zebra or column borders. Replaces Qt
// MarkdownText's cramped table rendering (which also mis-reports its height
// and overlaps following rows).
//
// Driven by a parsed segment:
//   headers : [string]
//   align   : ["left"|"right"|"center"]
//   rows    : [[string]]
//   weights : [int]   relative column widths (longest cell per column)
Item {
    id: root

    property var headers: []
    property var align: []
    property var rows: []
    property var weights: []

    readonly property int cols: headers ? headers.length : 0
    readonly property int cellPad: Theme.spacingS

    implicitHeight: grid.implicitHeight
    height: implicitHeight

    // Distribute the width across columns by weight, handing any rounding
    // remainder to the last column so cells tile exactly with no sub-pixel gaps.
    function _colWidth(idx) {
        if (cols <= 0) return 0
        const inner = width
        let total = 0
        for (let c = 0; c < cols; c++) total += (weights && weights[c] ? weights[c] : 1)
        if (total <= 0) total = cols
        if (idx < cols - 1)
            return Math.floor(inner * (weights && weights[idx] ? weights[idx] : 1) / total)
        let used = 0
        for (let c = 0; c < cols - 1; c++)
            used += Math.floor(inner * (weights && weights[c] ? weights[c] : 1) / total)
        return inner - used
    }

    function _colX(idx) {
        let x = 0
        for (let c = 0; c < idx; c++) x += _colWidth(c)
        return x
    }

    function _hAlign(idx) {
        const a = align && align[idx] ? align[idx] : "left"
        if (a === "right") return Text.AlignRight
        if (a === "center") return Text.AlignHCenter
        return Text.AlignLeft
    }

    // One reusable cell template: positioned by x/width, fills the row height,
    // and exposes its natural (wrapped) height via cellImplicit for measuring.
    component Cell: Item {
        id: cell
        property int col: 0
        property string value: ""
        property bool header: false
        // Natural height of this cell's wrapped text — used to size the row.
        readonly property real cellImplicit: cellText.implicitHeight + 2 * root.cellPad

        x: root._colX(col)
        width: root._colWidth(col)

        // TextEdit (not Text) so cell contents are selectable/copyable.
        TextEdit {
            id: cellText
            anchors.fill: parent
            anchors.topMargin: root.cellPad
            anchors.bottomMargin: root.cellPad
            // Flush left edge for the first column, like body text.
            anchors.leftMargin: cell.col === 0 ? 0 : root.cellPad
            anchors.rightMargin: cell.col === root.cols - 1 ? 0 : root.cellPad
            text: cell.value
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall
            font.weight: cell.header ? Font.Bold : Font.Normal
            wrapMode: TextEdit.WordWrap
            horizontalAlignment: root._hAlign(cell.col)
            verticalAlignment: TextEdit.AlignVCenter
            textFormat: cell.header ? TextEdit.PlainText : TextEdit.MarkdownText
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

    Column {
        id: grid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 0

        // ── Header row ──────────────────────────────────────────
        Item {
            width: parent.width
            height: headerRepeater.maxH

            // Rule under the header, slightly stronger than the row rules.
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.outlineMedium
            }

            Repeater {
                id: headerRepeater
                model: root.cols
                // Tallest cell drives the shared row height.
                property real maxH: 0
                function recompute() {
                    let m = 0
                    for (let k = 0; k < count; k++) {
                        const it = itemAt(k)
                        if (it && it.cellImplicit > m) m = it.cellImplicit
                    }
                    maxH = m
                }
                onItemAdded: recompute()
                delegate: Cell {
                    col: index
                    header: true
                    value: (root.headers && root.headers[index]) || ""
                    height: headerRepeater.maxH
                    onCellImplicitChanged: headerRepeater.recompute()
                }
            }
        }

        // ── Body rows ───────────────────────────────────────────
        Repeater {
            model: root.rows ? root.rows.length : 0

            delegate: Item {
                id: bodyRow
                width: grid.width
                property int rIndex: index
                property var cells: root.rows[index]
                height: rowRepeater.maxH + 1

                // Rule under each row.
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.outlineVariant
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: rowRepeater.maxH

                    Repeater {
                        id: rowRepeater
                        model: root.cols
                        property real maxH: 0
                        function recompute() {
                            let m = 0
                            for (let k = 0; k < count; k++) {
                                const it = itemAt(k)
                                if (it && it.cellImplicit > m) m = it.cellImplicit
                            }
                            maxH = m
                        }
                        onItemAdded: recompute()
                        delegate: Cell {
                            col: index
                            value: (bodyRow.cells && bodyRow.cells[index]) || ""
                            height: rowRepeater.maxH
                            onCellImplicitChanged: rowRepeater.recompute()
                        }
                    }
                }
            }
        }
    }
}

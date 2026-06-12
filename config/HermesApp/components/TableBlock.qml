import QtQuick
import qs.Common
import qs.Widgets

// A properly padded, bordered table. Replaces Qt MarkdownText's cramped table
// rendering (which also mis-reports its height and overlaps following rows).
//
// Driven by a parsed segment:
//   headers : [string]
//   align   : ["left"|"right"|"center"]
//   rows    : [[string]]
//   weights : [int]   relative column widths (longest cell per column)
Rectangle {
    id: root

    property var headers: []
    property var align: []
    property var rows: []
    property var weights: []

    readonly property int cols: headers ? headers.length : 0
    readonly property int cellPad: Theme.spacingS

    color: Theme.surfaceContainerHighest
    radius: Math.max(4, Theme.cornerRadius / 2)
    border.width: 1
    border.color: Theme.outlineVariant
    clip: true

    implicitHeight: grid.implicitHeight + 2 * border.width
    height: implicitHeight

    // Distribute the inner width across columns by weight, handing any rounding
    // remainder to the last column so cells tile exactly with no sub-pixel gaps.
    function _colWidth(idx) {
        if (cols <= 0) return 0
        const inner = width - 2 * border.width
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

        StyledText {
            id: cellText
            anchors.fill: parent
            anchors.margins: root.cellPad
            text: cell.value
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall
            font.weight: cell.header ? Font.Bold : Font.Normal
            wrapMode: Text.WordWrap
            horizontalAlignment: root._hAlign(cell.col)
            verticalAlignment: Text.AlignVCenter
            textFormat: cell.header ? Text.PlainText : Text.MarkdownText
        }

        // Column separator on the right edge (skip the last column).
        Rectangle {
            visible: cell.col < root.cols - 1
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Theme.outlineVariant
        }
    }

    Column {
        id: grid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.border.width
        spacing: 0

        // ── Header row ──────────────────────────────────────────
        Item {
            width: parent.width
            height: headerRepeater.maxH

            Rectangle {
                anchors.fill: parent
                color: Theme.surfaceContainerHigh
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

                // Row top border (grid line).
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.outlineVariant
                }

                // Zebra striping for readability.
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 1
                    color: (bodyRow.rIndex % 2 === 0)
                           ? "transparent"
                           : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g,
                                     Theme.surfaceText.b, 0.03)
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 1
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

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services

// cliphist clipboard history, top-right. Search field, numbered rows with
// image thumbnails / text preview, per-row delete, wipe-all. The expand button
// (or Tab) grows the panel leftwards into a preview pane that shows the full
// text / full-size image of the selected row; hover or Up/Down picks the row.

Panel {
    id: win

    name: "clipboard"
    keyboard: true
    slideFrom: Qt.TopEdge

    readonly property int listWidth: 560
    readonly property int maxWidth: win.parent ? win.parent.width - Theme.islandInset * 2 : 1200
    readonly property int maxHeight: win.parent ? win.parent.height - Theme.barHeight - 24 : 800

    width: Clip.expanded ? Math.min(1240, maxWidth) : listWidth
    height: Clip.expanded ? Math.min(780, maxHeight) : 640

    Behavior on width {
        Anim {
            type: Anim.Emphasized
        }
    }
    Behavior on height {
        Anim {
            type: Anim.Emphasized
        }
    }

    // Selected row, driven by hover and Up/Down.
    property int sel: 0
    readonly property var current: sel >= 0 && sel < Clip.filtered.length ? Clip.filtered[sel] : null
    readonly property string currentId: current ? current.id : ""

    // Debounced so sweeping the mouse over the list does not decode every row.
    onCurrentIdChanged: selTimer.restart()
    Timer {
        id: selTimer
        interval: 90
        onTriggered: {
            if (Clip.expanded && win.shown)
                Clip.select(win.current);
        }
    }
    Connections {
        target: Clip
        function onExpandedChanged() {
            if (Clip.expanded)
                selTimer.restart();
            else
                Clip.clearDetail();
        }
        function onQueryChanged() {
            win.sel = 0;
        }
    }

    function move(d) {
        const n = Clip.filtered.length;
        if (n === 0)
            return;
        win.sel = Math.max(0, Math.min(n - 1, win.sel + d));
        clipScroll.positionViewAtIndex(win.sel, ListView.Contain);
    }

    function copyCurrent() {
        if (!win.current)
            return;
        Clip.copy(win.current);
        Popups.close("clipboard", win.screenName);
    }

    onShownChanged: {
        if (shown) {
            Clip.query = "";
            search.text = "";
            win.sel = 0;
            Clip.refresh();
            search.forceActiveFocus();
        } else {
            wipeTimer.stop();
            card.clearing = false;
            Clip.clearDetail();
        }
    }


    Item {
        id: card
        anchors.fill: parent

        // Drives the staggered row slide-out; the timer waits for the last row
        // to finish before actually wiping the history.
        property bool clearing: false
        Timer {
            id: wipeTimer
            onTriggered: {
                Clip.wipe();
                card.clearing = false;
            }
        }
        // Anchored right so the list stays put while the preview grows in on
        // its left.
        Column {
            id: listCol
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 14
            width: win.listWidth - 28
            spacing: 12

            // header
            Row {
                width: parent.width
                spacing: 0
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    text: "󰅍"
                    font.family: Theme.fontMono
                    font.pixelSize: 20
                    color: Theme.accent
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 34 - 40 * 3
                    text: "Clipboard History (" + Clip.count + ")"
                    color: Theme.ink
                    font.family: Theme.fontSans
                    font.pixelSize: 17
                    font.weight: Font.Bold
                }
                StyledRect {
                    width: 34
                    height: 34
                    radius: 999
                    anchors.verticalCenter: parent.verticalCenter
                    color: (expandMa.containsMouse || Clip.expanded) ? Theme.card : "transparent"
                    StyledText {
                        anchors.centerIn: parent
                        text: Clip.expanded ? "󰊔" : "󰊓"
                        font.family: Theme.fontMono
                        font.pixelSize: 17
                        color: (expandMa.containsMouse || Clip.expanded) ? Theme.accent : Theme.inkDim
                    }
                    MouseArea {
                        id: expandMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Clip.expanded = !Clip.expanded
                    }
                }
                StyledRect {
                    width: 34
                    height: 34
                    radius: 999
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: card.clearing ? 0.5 : 1
                    color: (wipeMa.containsMouse && !card.clearing) ? Theme.card : "transparent"
                    StyledText {
                        anchors.centerIn: parent
                        text: "󰩹"
                        font.family: Theme.fontMono
                        font.pixelSize: 17
                        color: (wipeMa.containsMouse && !card.clearing) ? Theme.base08 : Theme.inkDim
                    }
                    MouseArea {
                        id: wipeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (card.clearing || Clip.count === 0)
                                return;
                            card.clearing = true;
                            wipeTimer.interval = (Clip.filtered.length - 1) * 50 + Theme.animDurations[Anim.EmphasizedAccel] + 80;
                            wipeTimer.restart();
                        }
                    }
                }
                StyledRect {
                    width: 34
                    height: 34
                    radius: 999
                    anchors.verticalCenter: parent.verticalCenter
                    color: closeMa.containsMouse ? Theme.card : "transparent"
                    StyledText {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.fontMono
                        font.pixelSize: 17
                        color: closeMa.containsMouse ? Theme.accent : Theme.inkDim
                    }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Popups.close("clipboard", win.screenName)
                    }
                }
            }

            // search
            StyledRect {
                width: parent.width
                height: 44
                radius: 999
                color: Theme.card
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        font.family: Theme.fontMono
                        font.pixelSize: 16
                        color: Theme.inkDim
                    }
                    TextField {
                        id: search
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 30
                        placeholderText: "Search clipboard…"
                        color: Theme.ink
                        font.family: Theme.fontSans
                        font.pixelSize: 14
                        background: null
                        onTextChanged: Clip.query = text
                        Keys.onEscapePressed: win.close()
                        Keys.onDownPressed: win.move(1)
                        Keys.onUpPressed: win.move(-1)
                        Keys.onReturnPressed: win.copyCurrent()
                        Keys.onEnterPressed: win.copyCurrent()
                        Keys.onTabPressed: Clip.expanded = !Clip.expanded
                    }
                }
            }

            // list
            // A ListView, not a Repeater: a Repeater builds an Image for
            // every history entry at once, so opening the panel decoded the
            // whole clipboard. This keeps only the visible rows alive.
            Item {
                width: parent.width
                height: parent.height - 44 - 34 - 24 - 24

                FadeListView {
                    id: clipScroll

                    anchors.fill: parent
                    spacing: 8
                    clip: true

                    model: ScriptModel {
                        values: Clip.filtered
                        objectProp: "id"
                    }

                    delegate: StyledRect {
                    id: crow
                    required property var modelData
                    required property int index
                    width: clipScroll.width - 4
                    radius: 14
                    readonly property bool selected: crow.index === win.sel
                    color: (crma.containsMouse || crow.selected) ? Theme.cardHi : Theme.card
                    border.width: crow.selected ? 1 : 0
                    border.color: Theme.accent
                    implicitHeight: 68

                    // Staggered slide-out on Wipe: rows glide off to the
                    // right + fade, delayed by position (mirrors ags
                    // .clip-row.clearing-out).
                    transform: Translate {
                        id: crowSlide
                    }
                    states: State {
                        name: "clearing"
                        when: card.clearing
                        PropertyChanges {
                            target: crowSlide
                            x: 600
                        }
                        PropertyChanges {
                            target: crow
                            opacity: 0
                        }
                    }
                    transitions: Transition {
                        to: "clearing"
                        SequentialAnimation {
                            PauseAnimation {
                                duration: crow.index * 50
                            }
                            ParallelAnimation {
                                Anim {
                                    target: crowSlide
                                    property: "x"
                                    type: Anim.EmphasizedAccel
                                }
                                Anim {
                                    target: crow
                                    property: "opacity"
                                    type: Anim.EmphasizedAccel
                                }
                            }
                        }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.right: delBtn.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        spacing: 12

                        StyledRect {
                            width: 30
                            height: 30
                            radius: 999
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.base02
                            StyledText {
                                anchors.centerIn: parent
                                text: crow.index + 1
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.accent
                            }
                        }

                        // thumbnail (image) or glyph (text)
                        Image {
                            visible: crow.modelData.isImage
                            anchors.verticalCenter: parent.verticalCenter
                            width: crow.modelData.isImage ? 60 : 0
                            height: 44
                            source: crow.modelData.isImage ? ("file://" + crow.modelData.thumb) : ""
                            fillMode: Image.PreserveAspectFit
                            cache: false
                            sourceSize.width: 120
                            sourceSize.height: 88
                        }
                        StyledText {
                            visible: !crow.modelData.isImage
                            anchors.verticalCenter: parent.verticalCenter
                            width: crow.modelData.isImage ? 0 : 44
                            text: "󰅎"
                            horizontalAlignment: Text.AlignHCenter
                            font.family: Theme.fontMono
                            font.pixelSize: 20
                            color: Theme.inkDim
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: crow.width - 30 - (crow.modelData.isImage ? 60 : 44) - delBtn.width - 60
                            spacing: 2
                            StyledText {
                                width: parent.width
                                text: crow.modelData.isImage ? ("Image • " + crow.modelData.dimensions + " " + crow.modelData.imageType.toUpperCase()) : "Text"
                                color: Theme.accent
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            StyledText {
                                width: parent.width
                                text: crow.modelData.preview
                                color: Theme.inkDim
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                    }

                    MouseArea {
                        id: crma
                        anchors.left: parent.left
                        anchors.right: delBtn.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.sel = crow.index
                        onClicked: {
                            Clip.copy(crow.modelData);
                            Popups.close("clipboard", win.screenName);
                        }
                    }

                    StyledRect {
                        id: delBtn
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 8
                        width: 36
                        height: 36
                        radius: 999
                        color: delMa.containsMouse ? Theme.base02 : "transparent"
                        StyledText {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: Theme.fontMono
                            font.pixelSize: 15
                            color: delMa.containsMouse ? Theme.base08 : Theme.inkDim
                        }
                        MouseArea {
                            id: delMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Clip.remove(crow.modelData)
                        }
                    }
                }
                }

                // empty state
                Column {
                    width: parent.width
                    visible: Clip.count === 0
                    topPadding: 160
                    spacing: 8
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰅎"
                        font.family: Theme.fontMono
                        font.pixelSize: 34
                        color: Theme.base03
                    }
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Clipboard is empty"
                        color: Theme.inkDim
                        font.family: Theme.fontSans
                        font.pixelSize: 13
                    }
                }
            }
        }

        // Preview pane: full text or full-size image of the selected row.
        StyledRect {
            id: pane

            readonly property var d: Clip.detail
            readonly property bool isImage: d ? d.isImage : false

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: listCol.left
            anchors.margins: 14
            anchors.rightMargin: 14

            radius: 14
            color: Theme.card
            clip: true
            visible: width > 60 && opacity > 0.01
            opacity: Clip.expanded ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Row {
                    id: paneHead
                    width: parent.width
                    height: 32

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - copyBtn.width - 12
                        elide: Text.ElideRight
                        color: Theme.accent
                        font.weight: Font.DemiBold
                        text: {
                            if (!pane.d)
                                return "Preview";
                            if (pane.isImage)
                                return "Image • " + pane.d.dimensions + " " + pane.d.imageType.toUpperCase() + " • " + pane.d.sizeText;
                            if (Clip.detailBusy)
                                return "Text";
                            return "Text • " + Clip.detailText.length + (Clip.detailTruncated ? "+" : "") + " chars • " + Clip.detailText.split("\n").length + " lines";
                        }
                    }
                    StyledRect {
                        id: copyBtn
                        anchors.verticalCenter: parent.verticalCenter
                        width: copyLabel.implicitWidth + 28
                        height: 32
                        radius: 999
                        visible: pane.d !== null
                        color: copyMa.containsMouse ? Theme.accent : Theme.cardHi
                        StyledText {
                            id: copyLabel
                            anchors.centerIn: parent
                            text: "󰆏  Copy"
                            font.family: Theme.fontMono
                            color: copyMa.containsMouse ? Theme.accentInk : Theme.ink
                        }
                        MouseArea {
                            id: copyMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!pane.d)
                                    return;
                                Clip.copy(pane.d);
                                Popups.close("clipboard", win.screenName);
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: parent.height - paneHead.height - 12

                    // text
                    FadeFlickable {
                        id: textFlick
                        anchors.fill: parent
                        visible: pane.d !== null && !pane.isImage && !Clip.detailBusy
                        contentWidth: width
                        contentHeight: fullText.implicitHeight
                        clip: true

                        StyledText {
                            id: fullText
                            width: textFlick.width - 8
                            text: Clip.detailText + (Clip.detailTruncated ? "\n\n… truncated" : "")
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            lineHeight: 1.15
                        }
                    }

                    // image
                    Image {
                        anchors.fill: parent
                        visible: pane.isImage && Clip.detailImage !== ""
                        source: Clip.detailImage !== "" ? "file://" + Clip.detailImage : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                        sourceSize.width: 1600
                    }

                    StyledText {
                        anchors.centerIn: parent
                        visible: pane.d === null || Clip.detailBusy
                        text: pane.d === null ? "Hover an entry to preview it" : "Loading…"
                        color: Theme.inkDim
                    }
                }
            }
        }
    }
}

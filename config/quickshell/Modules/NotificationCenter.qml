import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import qs.Common
import qs.Services

// Notification center + calendar + weather, top-center. Left: scrollable
// notification list with DND toggle + clear-all. Right: date, current month
// calendar, Open-Meteo weather card.

Panel {
    id: win

    name: "notes"
    keyboard: true
    slideFrom: Qt.TopEdge

    width: 800
    height: 560

    onShownChanged: {
        if (shown)
            Weather.fetchNow();
        else {
            clearTimer.stop();
            card.clearing = false;
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Elevation {
        anchors.fill: card
        radius: card.radius
        level: 4
    }

    StyledRect {
        id: card
        anchors.fill: parent
        radius: 22
        color: Theme.base00
        border.width: 1
        border.color: Theme.base02

        // Drives the staggered card slide-out; the timer waits for the last
        // card to finish before actually dismissing them all.
        property bool clearing: false
        Timer {
            id: clearTimer
            onTriggered: {
                Notif.clearAll();
                card.clearing = false;
            }
        }
        Row {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 0

            // ── LEFT: notification list ──
            Item {
                width: 420
                height: parent.height

                Column {
                    anchors.fill: parent
                    anchors.rightMargin: 16 // breathing room before the divider
                    spacing: 8

                    // A ListView, not a Repeater over the whole list: Notif.list
                    // grows all session, and a Repeater would hold a decoded
                    // Image for every notification ever received. This keeps
                    // only the visible rows alive.
                    Item {
                        width: parent.width
                        height: parent.height - footer.height - 8

                        FadeListView {
                            id: nlistScroll

                            anchors.fill: parent
                            spacing: 6
                            clip: true

                            model: ScriptModel {
                                values: Notif.list
                            }

                            delegate: StyledRect {
                            id: ncard
                            required property var modelData
                            required property int index
                            readonly property var n: modelData.n
                            readonly property var acts: Notif.visibleActions(n)
                            width: nlistScroll.width - 4
                            radius: 12
                            color: ncma.containsMouse ? Theme.cardHi : Theme.card
                            border.width: n.urgency === NotificationUrgency.Critical ? 1 : 0
                            border.color: Theme.base08
                            implicitHeight: ncontent.implicitHeight + 18

                            // Staggered slide-out on Clear all: each card glides
                            // off to the right + fades, delayed by its position
                            // (mirrors ags .ncard.clearing-out). Translate keeps
                            // the Column positioner from fighting the motion.
                            transform: Translate {
                                id: ncardSlide
                            }
                            states: State {
                                name: "clearing"
                                when: card.clearing
                                PropertyChanges {
                                    target: ncardSlide
                                    x: 520
                                }
                                PropertyChanges {
                                    target: ncard
                                    opacity: 0
                                }
                            }
                            transitions: Transition {
                                to: "clearing"
                                SequentialAnimation {
                                    PauseAnimation {
                                        duration: ncard.index * 50
                                    }
                                    ParallelAnimation {
                                        Anim {
                                            target: ncardSlide
                                            property: "x"
                                            type: Anim.EmphasizedAccel
                                        }
                                        Anim {
                                            target: ncard
                                            property: "opacity"
                                            type: Anim.EmphasizedAccel
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: ncma
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            Row {
                                id: ncontent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 9
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                // icon / image
                                StyledRect {
                                    width: 34
                                    height: 34
                                    radius: 999
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: ncard.n.image ? "transparent" : Theme.base02
                                    clip: true
                                    Image {
                                        anchors.fill: parent
                                        source: ncard.n.image || ""
                                        visible: status === Image.Ready
                                        fillMode: Image.PreserveAspectCrop
                                        // Without this a screenshot notification
                                        // decodes at full resolution for a 34px avatar.
                                        sourceSize.width: 68
                                        sourceSize.height: 68
                                    }
                                    StyledText {
                                        anchors.centerIn: parent
                                        visible: !ncard.n.image
                                        text: "󰂚"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 15
                                        color: Theme.accent
                                    }
                                }

                                Column {
                                    // Reference the card's explicit width, NOT parent (the Row):
                                    // a Row sizes to its children, so `parent.width - N` here
                                    // would be a circular dependency that collapses the text.
                                    // card width − (12+12 margins + 34 icon + 10 spacing).
                                    width: ncard.width - 68
                                    spacing: 1
                                    Row {
                                        width: parent.width
                                        spacing: 6
                                        StyledText {
                                            width: parent.width - tt.width - cl.width - 12
                                            text: ncard.n.summary || ncard.n.appName || "Notification"
                                            color: Theme.ink
                                            font.family: Theme.fontSans
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        StyledText {
                                            id: tt
                                            text: Qt.formatDateTime(new Date(ncard.modelData.time), "HH:mm")
                                            color: Theme.inkDim
                                            font.family: Theme.fontSans
                                            font.pixelSize: 11
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        StyledText {
                                            id: cl
                                            text: "󰅖"
                                            color: clma.containsMouse ? Theme.base08 : Theme.inkDim
                                            font.family: Theme.fontMono
                                            font.pixelSize: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            MouseArea {
                                                id: clma
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Notif.dismiss(ncard.n)
                                            }
                                        }
                                    }
                                    StyledText {
                                        width: parent.width
                                        visible: (ncard.n.body || "") !== ""
                                        text: ncard.n.body || ""
                                        color: Theme.inkDim
                                        font.family: Theme.fontSans
                                        font.pixelSize: 12
                                        textFormat: Text.MarkdownText
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                    }
                                    Row {
                                        spacing: 6
                                        visible: ncard.acts.length > 0
                                        topPadding: 4
                                        Repeater {
                                            model: ncard.acts
                                            delegate: StyledRect {
                                                id: nab
                                                required property var modelData
                                                width: nabt.implicitWidth + 20
                                                height: 26
                                                radius: 9
                                                color: nabma.containsMouse ? Theme.accent : Theme.base02
                                                StyledText {
                                                    id: nabt
                                                    anchors.centerIn: parent
                                                    text: nab.modelData.text
                                                    color: nabma.containsMouse ? Theme.accentInk : Theme.ink
                                                    font.family: Theme.fontSans
                                                    font.pixelSize: 12
                                                }
                                                MouseArea {
                                                    id: nabma
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: nab.modelData.invoke()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        }

                        // empty state
                        Column {
                            width: parent.width
                            visible: Notif.list.length === 0
                            topPadding: 120
                            spacing: 8
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰂚"
                                font.family: Theme.fontMono
                                font.pixelSize: 34
                                color: Theme.base03
                            }
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No notifications"
                                color: Theme.inkDim
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                            }
                        }
                    }

                    // footer: DND toggle + clear
                    Item {
                        id: footer
                        width: parent.width
                        height: 40
                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Do Not Disturb"
                                color: Theme.ink
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            StyledRect {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 42
                                height: 22
                                radius: 999
                                color: Notif.dnd ? Theme.accent : Theme.base02
                                StyledRect {
                                    width: 16
                                    height: 16
                                    radius: 999
                                    y: 3
                                    x: Notif.dnd ? parent.width - width - 3 : 3
                                    color: Notif.dnd ? Theme.accentInk : Theme.ink
                                    Behavior on x {
                                        Anim {
                                            type: Anim.FastSpatial
                                        }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notif.toggleDnd()
                                }
                            }
                        }
                        StyledRect {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: clrTxt.implicitWidth + 36
                            height: 34
                            radius: 10
                            opacity: card.clearing ? 0.5 : 1
                            color: (clrMa.containsMouse && !card.clearing) ? Theme.accent : Theme.card
                            StyledText {
                                id: clrTxt
                                anchors.centerIn: parent
                                text: "Clear all"
                                color: (clrMa.containsMouse && !card.clearing) ? Theme.accentInk : Theme.ink
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                            }
                            MouseArea {
                                id: clrMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (card.clearing || Notif.list.length === 0)
                                        return;
                                    card.clearing = true;
                                    // last card's delay + slide + a little slack
                                    clearTimer.interval = (Notif.list.length - 1) * 50 + Theme.animDurations[Anim.EmphasizedAccel] + 80;
                                    clearTimer.restart();
                                }
                            }
                        }
                    }
                }
            }

            // divider
            StyledRect {
                width: 1
                height: parent.height - 12
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.base02
            }

            // ── RIGHT: date · calendar · weather ──
            Item {
                width: parent.width - 420 - 1
                height: parent.height

                Column {
                    id: rightCol
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 4
                    spacing: 12

                    // Calendar block and weather card split the space left under
                    // the date header equally, so the two fill the right side
                    // symmetrically (3 children → 2 gaps of `spacing`).
                    readonly property real blockH: (height - rightHeader.height - spacing * 2) / 2

                    Column {
                        id: rightHeader
                        width: parent.width
                        spacing: 2
                        StyledText {
                            text: Qt.formatDateTime(clock.date, "dddd")
                            color: Theme.inkDim
                            font.family: Theme.fontSans
                            font.pixelSize: 14
                        }
                        StyledText {
                            text: Qt.formatDateTime(clock.date, "d MMMM yyyy")
                            color: Theme.ink
                            font.family: Theme.fontSans
                            font.pixelSize: 22
                            font.weight: Font.Bold
                        }
                    }

                    // compact current-month calendar, vertically centred in its half
                    Item {
                        width: parent.width
                        height: rightCol.blockH

                        Grid {
                        id: cal
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        columns: 7
                        rowSpacing: 4
                        columnSpacing: 0
                        readonly property real cw: width / 7
                        readonly property var today: clock.date

                        Repeater {
                            model: ["S", "M", "T", "W", "T", "F", "S"]
                            delegate: Item {
                                required property var modelData
                                width: cal.cw
                                height: 26
                                StyledText {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: Theme.inkDim
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        Repeater {
                            model: {
                                const d = cal.today;
                                const year = d.getFullYear();
                                const month = d.getMonth();
                                const first = new Date(year, month, 1).getDay();
                                const days = new Date(year, month + 1, 0).getDate();
                                const cells = [];
                                for (let i = 0; i < first; i++)
                                    cells.push(0);
                                for (let day = 1; day <= days; day++)
                                    cells.push(day);
                                return cells;
                            }
                            delegate: Item {
                                required property var modelData
                                readonly property bool isToday: modelData === cal.today.getDate()
                                width: cal.cw
                                height: 34
                                StyledRect {
                                    anchors.centerIn: parent
                                    width: 30
                                    height: 30
                                    radius: 999
                                    visible: parent.isToday
                                    color: Theme.accent
                                }
                                StyledText {
                                    anchors.centerIn: parent
                                    visible: modelData > 0
                                    text: modelData > 0 ? modelData : ""
                                    color: parent.isToday ? Theme.accentInk : Theme.ink
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                                }
                            }
                        }
                        }
                    }

                    // ── weather card (fills the lower half symmetrically) ──
                    StyledRect {
                        width: parent.width
                        height: rightCol.blockH
                        radius: 12
                        color: Theme.card

                        Column {
                            id: wcol
                            anchors.fill: parent
                            anchors.margins: 12
                            // Size the three blocks + two separators to their
                            // content and spread the leftover space evenly between
                            // them (5 children → 4 gaps), so the rows keep a
                            // consistent vertical rhythm.
                            spacing: Weather.status === "ready"
                                ? Math.max(0, (height - curBlock.height - detailsRow.height - hourlyRow.height - wsep1.height - wsep2.height) / 4)
                                : 0

                            // loading / error
                            StyledText {
                                visible: Weather.status !== "ready"
                                text: Weather.status === "error" ? "Weather unavailable" : "Loading weather…"
                                color: Weather.status === "error" ? Theme.base08 : Theme.inkDim
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                            }

                            // current conditions — icon + temp/desc on the left,
                            // location pinned to the right (anchored, so it can't
                            // overflow the card like a fixed-width spacer would)
                            Item {
                                id: curBlock
                                visible: Weather.status === "ready"
                                width: parent.width
                                height: Math.max(curIcon.height, curTemp.height)

                                StyledText {
                                    id: curIcon
                                    // ink-centred over the first grid column below
                                    x: curBlock.width / 10 - (curTm.tightBoundingRect.x + curTm.tightBoundingRect.width / 2)
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Weather.current ? Weather.wmoInfo(Weather.current.weatherCode, Weather.current.isDay).icon : ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 32
                                    color: Theme.accent
                                    TextMetrics {
                                        id: curTm
                                        font: curIcon.font
                                        text: curIcon.text
                                    }
                                }
                                Column {
                                    id: curTemp
                                    anchors.left: curIcon.right
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    StyledText {
                                        text: Weather.current ? Weather.current.temp + "°C" : ""
                                        color: Theme.ink
                                        font.family: Theme.fontSans
                                        font.pixelSize: 22
                                        font.weight: Font.Bold
                                    }
                                    StyledText {
                                        text: Weather.current ? Weather.wmoInfo(Weather.current.weatherCode, Weather.current.isDay).desc : ""
                                        color: Theme.inkDim
                                        font.family: Theme.fontSans
                                        font.pixelSize: 12
                                    }
                                }
                                Column {
                                    // pinned to the card's right edge, both lines
                                    // flush right
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    StyledText {
                                        anchors.right: parent.right
                                        text: Weather.locationName
                                        color: Theme.inkDim
                                        font.family: Theme.fontSans
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                    StyledText {
                                        anchors.right: parent.right
                                        text: Weather.current ? "Feels " + Weather.current.feelsLike + "°" : ""
                                        color: Theme.base03
                                        font.family: Theme.fontSans
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            StyledRect {
                                id: wsep1
                                visible: Weather.status === "ready"
                                width: parent.width
                                height: 1
                                color: Theme.base03
                                opacity: 0.25
                            }

                            // Each metric owns one fixed-width column. Keeping the
                            // icon/value/label together avoids Grid laying out the
                            // three repeaters as independently-sized rows.
                            Row {
                                id: detailsRow
                                visible: Weather.status === "ready" && Weather.current
                                width: parent.width
                                readonly property var metrics: Weather.current ? [
                                    { i: "󰖎", v: Weather.current.humidity + "%", l: "HUMIDITY" },
                                    { i: "󰖝", v: Weather.current.windSpeed + " " + Weather.windDirToCompass(Weather.current.windDir), l: "WIND" },
                                    { i: "󰓅", v: "" + Weather.current.uvIndex, l: "UV INDEX" },
                                    { i: "󰖛", v: Weather.current.cloudCover + "%", l: "CLOUDS" },
                                    { i: "󰖗", v: Weather.current.precipitation + " mm", l: "RAIN" }
                                ] : []
                                // clean grid: equal-width cells, everything centered.
                                // Both this row and the hourly strip have 5 columns,
                                // so the column centre-lines run straight through both.
                                readonly property real cellW: width / Math.max(1, metrics.length)

                                Repeater {
                                    model: detailsRow.metrics
                                    delegate: Column {
                                        required property var modelData
                                        width: detailsRow.cellW
                                        spacing: 2
                                        // centre the icon by its painted ink, not its
                                        // advance box — Nerd Font glyphs overflow the
                                        // box and lean right when box-centred
                                        Item {
                                            width: parent.width
                                            height: mIcon.height
                                            StyledText {
                                                id: mIcon
                                                x: parent.width / 2 - (mTm.tightBoundingRect.x + mTm.tightBoundingRect.width / 2)
                                                text: modelData.i
                                                color: Theme.accent
                                                font.family: Theme.fontMono
                                                font.pixelSize: 16
                                                TextMetrics {
                                                    id: mTm
                                                    font: mIcon.font
                                                    text: mIcon.text
                                                }
                                            }
                                        }
                                        StyledText {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.v
                                            color: Theme.ink
                                            font.family: Theme.fontSans
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                        }
                                        StyledText {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.l
                                            color: Theme.base03
                                            font.family: Theme.fontSans
                                            font.pixelSize: 9
                                        }
                                    }
                                }
                            }

                            StyledRect {
                                id: wsep2
                                visible: Weather.status === "ready"
                                width: parent.width
                                height: 1
                                color: Theme.base03
                                opacity: 0.25
                            }

                            // One column per hour keeps time/icon/temp/rain as a
                            // single aligned unit across the five-hour strip.
                            Row {
                                id: hourlyRow
                                visible: Weather.status === "ready"
                                width: parent.width
                                // same equal-cell centred grid as the details row
                                readonly property real cellW: width / Math.max(1, Weather.hourly.length)

                                Repeater {
                                    model: Weather.hourly
                                    delegate: Column {
                                        required property var modelData
                                        width: hourlyRow.cellW
                                        spacing: 2
                                        StyledText {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.time.slice(11, 16)
                                            color: Theme.base03
                                            font.family: Theme.fontSans
                                            font.pixelSize: 9
                                        }
                                        // ink-centred like the details-row icons
                                        Item {
                                            width: parent.width
                                            height: hIcon.height
                                            StyledText {
                                                id: hIcon
                                                x: parent.width / 2 - (hTm.tightBoundingRect.x + hTm.tightBoundingRect.width / 2)
                                                text: Weather.wmoInfo(modelData.weatherCode, true).icon
                                                font.family: Theme.fontMono
                                                font.pixelSize: 18
                                                color: Theme.accent
                                                TextMetrics {
                                                    id: hTm
                                                    font: hIcon.font
                                                    text: hIcon.text
                                                }
                                            }
                                        }
                                        StyledText {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.temp + "°"
                                            color: Theme.ink
                                            font.family: Theme.fontSans
                                            font.pixelSize: 14
                                            font.weight: Font.Bold
                                        }
                                        StyledText {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.precipProb + "%"
                                            color: modelData.precipProb > 0 ? Theme.base0D : Theme.base03
                                            opacity: modelData.precipProb > 0 ? 1 : 0.45
                                            font.family: Theme.fontSans
                                            font.pixelSize: 9
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

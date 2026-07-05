import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.Common
import qs.Services

// Notification center + calendar + weather, top-center (mirrors ags
// NotificationCenter). Left: scrollable notification list with DND toggle +
// clear-all. Right: date, current month calendar, Open-Meteo weather card.

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property string screenName: screen ? screen.name : ""

    visible: Popups.isOpen("notes", win.screenName)
    onVisibleChanged: if (visible)
        Weather.fetchNow()
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0
    anchors.top: true
    implicitWidth: card.width + 16
    implicitHeight: card.height + 16

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 8
        width: 800
        height: 560
        radius: 22
        color: Theme.base00
        border.width: 1
        border.color: Theme.base02
        focus: win.visible
        Keys.onEscapePressed: Popups.close("notes", win.screenName)

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
        // Reset if the panel is hidden mid-clear.
        Connections {
            target: win
            function onVisibleChanged() {
                if (!win.visible) {
                    clearTimer.stop();
                    card.clearing = false;
                }
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

                    ScrollView {
                        id: nlistScroll
                        width: parent.width
                        height: parent.height - footer.height - 8
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        Column {
                            // ScrollView viewport width — `parent.width` inside a
                            // Controls ScrollView is the flickable's content width (~0).
                            width: nlistScroll.availableWidth
                            spacing: 6

                            Repeater {
                                model: Notif.list
                                delegate: Rectangle {
                                    id: ncard
                                    required property var modelData
                                    required property int index
                                    readonly property var n: modelData.n
                                    readonly property var acts: Notif.visibleActions(n)
                                    width: parent.width - 4
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
                                                NumberAnimation {
                                                    target: ncardSlide
                                                    property: "x"
                                                    duration: 350
                                                    easing.type: Easing.InCubic
                                                }
                                                NumberAnimation {
                                                    target: ncard
                                                    property: "opacity"
                                                    duration: 350
                                                    easing.type: Easing.InCubic
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
                                        Rectangle {
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
                                            }
                                            Text {
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
                                                Text {
                                                    width: parent.width - tt.width - cl.width - 12
                                                    text: ncard.n.summary || ncard.n.appName || "Notification"
                                                    color: Theme.ink
                                                    font.family: Theme.fontSans
                                                    font.pixelSize: 13
                                                    font.weight: Font.DemiBold
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    id: tt
                                                    text: Qt.formatDateTime(new Date(ncard.modelData.time), "HH:mm")
                                                    color: Theme.inkDim
                                                    font.family: Theme.fontSans
                                                    font.pixelSize: 11
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                                Text {
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
                                            Text {
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
                                                    delegate: Rectangle {
                                                        id: nab
                                                        required property var modelData
                                                        width: nabt.implicitWidth + 20
                                                        height: 26
                                                        radius: 9
                                                        color: nabma.containsMouse ? Theme.accent : Theme.base02
                                                        Text {
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
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "󰂚"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 34
                                    color: Theme.base03
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "No notifications"
                                    color: Theme.inkDim
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                }
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
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Do Not Disturb"
                                color: Theme.ink
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 42
                                height: 22
                                radius: 999
                                color: Notif.dnd ? Theme.accent : Theme.base02
                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 999
                                    y: 3
                                    x: Notif.dnd ? parent.width - width - 3 : 3
                                    color: Notif.dnd ? Theme.accentInk : Theme.ink
                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 150
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
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: clrTxt.implicitWidth + 36
                            height: 34
                            radius: 10
                            opacity: card.clearing ? 0.5 : 1
                            color: (clrMa.containsMouse && !card.clearing) ? Theme.accent : Theme.card
                            Text {
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
                                    clearTimer.interval = (Notif.list.length - 1) * 50 + 350 + 80;
                                    clearTimer.restart();
                                }
                            }
                        }
                    }
                }
            }

            // divider
            Rectangle {
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
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 4
                    spacing: 10

                    Text {
                        text: Qt.formatDateTime(clock.date, "dddd")
                        color: Theme.inkDim
                        font.family: Theme.fontSans
                        font.pixelSize: 14
                    }
                    Text {
                        text: Qt.formatDateTime(clock.date, "d MMMM yyyy")
                        color: Theme.ink
                        font.family: Theme.fontSans
                        font.pixelSize: 22
                        font.weight: Font.Bold
                    }

                    // compact current-month calendar
                    Grid {
                        id: cal
                        width: parent.width
                        columns: 7
                        rowSpacing: 2
                        columnSpacing: 0
                        readonly property real cw: width / 7
                        readonly property var today: clock.date

                        Repeater {
                            model: ["S", "M", "T", "W", "T", "F", "S"]
                            delegate: Item {
                                required property var modelData
                                width: cal.cw
                                height: 26
                                Text {
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
                                height: 30
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 28
                                    height: 28
                                    radius: 999
                                    visible: parent.isToday
                                    color: Theme.accent
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: modelData > 0
                                    text: modelData > 0 ? modelData : ""
                                    color: parent.isToday ? Theme.accentInk : Theme.ink
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                                }
                            }
                        }
                    }

                    // ── weather card ──
                    Rectangle {
                        width: parent.width
                        radius: 12
                        color: Theme.card
                        implicitHeight: wcol.implicitHeight + 24

                        Column {
                            id: wcol
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 12
                            spacing: 8

                            // loading / error
                            Text {
                                visible: Weather.status !== "ready"
                                text: Weather.status === "error" ? "Weather unavailable" : "Loading weather…"
                                color: Weather.status === "error" ? Theme.base08 : Theme.inkDim
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                            }

                            // current conditions
                            Row {
                                visible: Weather.status === "ready"
                                width: parent.width
                                spacing: 12
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Weather.current ? Weather.wmoInfo(Weather.current.weatherCode, Weather.current.isDay).icon : ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 32
                                    color: Theme.accent
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Text {
                                        text: Weather.current ? Weather.current.temp + "°C" : ""
                                        color: Theme.ink
                                        font.family: Theme.fontSans
                                        font.pixelSize: 22
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        text: Weather.current ? Weather.wmoInfo(Weather.current.weatherCode, Weather.current.isDay).desc : ""
                                        color: Theme.inkDim
                                        font.family: Theme.fontSans
                                        font.pixelSize: 12
                                    }
                                }
                                Item {
                                    width: parent.width - 200
                                    height: 1
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        anchors.right: parent.right
                                        text: Weather.locationName
                                        color: Theme.inkDim
                                        font.family: Theme.fontSans
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        text: Weather.current ? "Feels " + Weather.current.feelsLike + "°" : ""
                                        color: Theme.base03
                                        font.family: Theme.fontSans
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            // details row
                            Row {
                                visible: Weather.status === "ready" && Weather.current
                                width: parent.width
                                topPadding: 8
                                bottomPadding: 8
                                Repeater {
                                    model: Weather.current ? [
                                        {
                                            v: Weather.current.humidity + "%",
                                            l: "HUMIDITY"
                                        },
                                        {
                                            v: Weather.current.windSpeed + " " + Weather.windDirToCompass(Weather.current.windDir),
                                            l: "WIND"
                                        },
                                        {
                                            v: "" + Weather.current.uvIndex,
                                            l: "UV INDEX"
                                        }
                                    ] : []
                                    delegate: Column {
                                        required property var modelData
                                        width: (wcol.width) / 3
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.v
                                            color: Theme.ink
                                            font.family: Theme.fontSans
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.l
                                            color: Theme.base03
                                            font.family: Theme.fontSans
                                            font.pixelSize: 9
                                        }
                                    }
                                }
                            }

                            // hourly strip
                            Row {
                                visible: Weather.status === "ready"
                                width: parent.width
                                Repeater {
                                    model: Weather.hourly
                                    delegate: Column {
                                        required property var modelData
                                        width: wcol.width / Math.max(1, Weather.hourly.length)
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.time.slice(11, 16)
                                            color: Theme.base03
                                            font.family: Theme.fontSans
                                            font.pixelSize: 9
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: Weather.wmoInfo(modelData.weatherCode, true).icon
                                            font.family: Theme.fontMono
                                            font.pixelSize: 17
                                            color: Theme.accent
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.temp + "°"
                                            color: Theme.ink
                                            font.family: Theme.fontSans
                                            font.pixelSize: 14
                                            font.weight: Font.Bold
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
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

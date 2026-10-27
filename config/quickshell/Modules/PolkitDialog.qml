pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Polkit
import qs.Common

// In-shell polkit agent. Only one agent may register per session, so
// hyprland.nix starts lxpolkit only for the other widget stacks. Each request
// opens a dialog on the focused monitor over a scrim, holding the keyboard
// exclusively until it is answered or cancelled; the window lives only while
// a request is open (plus its exit animation).
Scope {
    id: root

    PolkitAgent {
        id: agent
    }

    readonly property var flow: agent.flow
    // A request whose caller died stays "active" with a finished flow, so the
    // flow's own state decides. `dismissed` is the local failsafe: Esc or
    // Cancel always closes the window, even if polkit never answers.
    property var dismissed: null
    readonly property bool open: agent.isActive && flow !== null && !flow.isCompleted && !flow.isCancelled && dismissed !== flow

    LazyLoader {
        id: loader

        // Kept alive through the fade-out, then dropped.
        property bool closing: false

        active: root.open || closing

        PanelWindow {
            id: win

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            color: "transparent"

            WlrLayershell.namespace: "quickshell-polkit"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            property real shown: 0
            property bool busy: false

            function fadeTo(v) {
                fade.stop();
                fade.to = v;
                fade.type = v > 0 ? Anim.Emphasized : Anim.EmphasizedAccel;
                fade.start();
            }

            Component.onCompleted: fadeTo(1)

            Connections {
                target: root

                function onOpenChanged() {
                    loader.closing = !root.open;
                    if (root.open)
                        failsafe.stop();
                    else
                        failsafe.restart();
                    win.fadeTo(root.open ? 1 : 0);
                }
            }

            Anim {
                id: fade

                target: win
                property: "shown"
                onFinished: if (!root.open)
                    loader.closing = false
            }
            // The window holds the keyboard exclusively, so it must go even if
            // the exit animation never completes.
            Timer {
                id: failsafe

                interval: 600
                onTriggered: loader.closing = false
            }

            Connections {
                target: root.flow

                function onIsResponseRequiredChanged() {
                    if (root.flow?.isResponseRequired) {
                        win.busy = false;
                        input.text = "";
                        input.forceActiveFocus();
                    }
                }
                function onAuthenticationFailed() {
                    win.busy = false;
                    input.text = "";
                    shake.shake();
                }
            }

            function submit() {
                if (!root.flow || win.busy || input.text === "")
                    return;
                win.busy = true;
                root.flow.submit(input.text);
            }
            function cancel() {
                const f = root.flow;
                root.dismissed = f;
                f?.cancelAuthenticationRequest();
            }

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.5 * win.shown
            }

            Elevation {
                anchors.fill: card
                radius: card.radius
                level: 5
                opacity: win.shown
            }

            StyledRect {
                id: card

                anchors.centerIn: parent
                width: 400
                height: body.implicitHeight + 48
                radius: 28
                color: Theme.base00
                border.width: 1
                border.color: Theme.base02
                opacity: win.shown
                scale: 0.92 + 0.08 * win.shown

                transform: Shake {
                    id: shake
                }

                Column {
                    id: body

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24
                    spacing: 14

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 60
                        height: 60

                        PolarShape {
                            anchors.fill: parent
                            lobes: 8
                            amplitude: 0.07
                            fillColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                        }
                        StyledIcon {
                            anchors.centerIn: parent
                            text: "󰒃"
                            color: Theme.accent
                            font.pixelSize: 26
                        }
                    }

                    StyledText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "Authentication required"
                        color: Theme.base07
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: root.flow?.message ?? ""
                        color: Theme.inkDim
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                    StyledText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        readonly property var who: root.flow?.selectedIdentity ?? null
                        visible: text !== ""
                        text: who ? "as " + (who.displayName || who.name || Quickshell.env("USER")) : ""
                        color: Theme.inkDim
                        font.pixelSize: 11
                    }

                    StyledRect {
                        width: parent.width
                        height: 46
                        radius: height / 2
                        color: Theme.card
                        border.width: 2
                        border.color: root.flow?.supplementaryIsError ? Theme.base08 : input.activeFocus ? Theme.accent : Theme.base02

                        TextInput {
                            id: input

                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "●"
                            color: Theme.ink
                            selectionColor: Theme.accent
                            font.family: Theme.fontSans
                            font.pixelSize: 14
                            readOnly: win.busy
                            focus: true
                            Component.onCompleted: forceActiveFocus()

                            Keys.onReturnPressed: win.submit()
                            Keys.onEnterPressed: win.submit()
                            Keys.onEscapePressed: win.cancel()
                        }
                        StyledText {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
                            color: Theme.inkDim
                            font.pixelSize: 13
                        }
                    }

                    StyledText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                        text: root.flow?.supplementaryMessage ?? ""
                        color: root.flow?.supplementaryIsError ? Theme.base08 : Theme.inkDim
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }

                    Row {
                        anchors.right: parent.right
                        spacing: 8

                        StyledRect {
                            width: cancelText.implicitWidth + 32
                            height: 40
                            radius: 20

                            StyledText {
                                id: cancelText

                                anchors.centerIn: parent
                                text: "Cancel"
                                color: Theme.accent
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            StateLayer {
                                color: Theme.accent
                                onClicked: win.cancel()
                            }
                        }
                        StyledRect {
                            width: 136
                            height: 40
                            radius: 20
                            color: input.text !== "" || win.busy ? Theme.accent : Theme.base02

                            StyledText {
                                anchors.centerIn: parent
                                visible: !win.busy
                                text: "Authenticate"
                                color: input.text !== "" ? Theme.accentInk : Theme.inkDim
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            LoadingIndicator {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                running: win.busy
                                color: Theme.accentInk
                            }
                            StateLayer {
                                color: Theme.accentInk
                                disabled: input.text === "" || win.busy
                                onClicked: win.submit()
                            }
                        }
                    }
                }
            }
        }
    }
}

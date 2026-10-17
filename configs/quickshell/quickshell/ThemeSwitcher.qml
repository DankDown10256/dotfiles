
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    property string homePath: Quickshell.env("HOME")

    required property var colors

    property bool open: false
    property bool alive: false
    property int selectedIndex: {
        const index = themeModel.findIndex(item => item.id === colors.scheme)
        return index >= 0 ? index : 0
    }

    readonly property var themeModel: [
        { id: "github-dark", name: "GitHub", accent: "#58a6ff" },
        { id: "catppuccin", name: "Catppuccin", accent: "#cba6f7" },
        { id: "warm", name: "Warm", accent: "#d97757" },
        { id: "e-ink", name: "E-Ink", accent: "#d0d0d0" },
        { id: "claude-light", name: "Claude Light", accent: "#c16b45" }
    ]

    function applyTheme(index) {
        if (index < 0 || index >= themeModel.length)
            return

        selectedIndex = index
        colors.setScheme(themeModel[index].id)
        if (themeModel[index].id === "warm") {
           Quickshell.execDetached(["awww", "img", homePath + "/macos-sequoia-default-wallpaper.png"]) 
        } else if (themeModel[index].id === "github-dark") {
           Quickshell.execDetached(["awww", "img", homePath + "/beach.jpg"]) 
         } else if (themeModel[index].id === "e-ink") {
           Quickshell.execDetached(["awww", "img", homePath + "/red_eyes.jpg"])
        }

        open = false
    }

    function moveSelection(delta) {
        selectedIndex =
            (selectedIndex + delta + themeModel.length) % themeModel.length
    }

    IpcHandler {
        target: "themes"

        function toggle(): void {
            root.open = !root.open
        }

        function show(): void {
            root.open = true
        }

        function hide(): void {
            root.open = false
        }
    }

    onOpenChanged: {
        if (open) {
            alive = true
            closeTimer.stop()
            Qt.callLater(() => keyboardTarget.forceActiveFocus())
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: root.alive = false
    }

    LazyLoader {
        active: root.alive

        PanelWindow {
            id: panel

            anchors {
                left: true
                right: true
                bottom: true
            }

            implicitHeight: 110
            color: "transparent"
            exclusiveZone: 0

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

            Item {
                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                    enabled: root.open
                    onClicked: root.open = false
                }

                Rectangle {
                    id: capsule

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: shown ? 44 : 36

                    width: Math.min(540, parent.width - 32)
                    height: 56
                    radius: 20

                    color: root.colors.cSurface
                    border.width: 1
                    border.color: Qt.alpha(root.colors.cBorder, 0.65)

                    property bool shown: false
                    opacity: shown ? 1 : 0
                    scale: shown ? 1 : 0.98

                    Component.onCompleted: Qt.callLater(() => shown = root.open)

                    Connections {
                        target: root
                        function onOpenChanged() { capsule.shown = root.open }
                    }

                    Behavior on anchors.bottomMargin {
                        NumberAnimation {
                            duration: capsule.shown ? 200 : 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: capsule.shown ? 200 : 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: capsule.shown ? 200 : 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {}
                    }

                    Item {
                        id: keyboardTarget

                        anchors.fill: parent
                        focus: root.open

                        Keys.onPressed: event => {
                            if (!root.open)
                                return

                            if (event.key === Qt.Key_Left) {
                                root.moveSelection(-1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Right) {
                                root.moveSelection(1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Home) {
                                root.selectedIndex = 0
                                event.accepted = true
                            } else if (event.key === Qt.Key_End) {
                                root.selectedIndex = root.themeModel.length - 1
                                event.accepted = true
                            } else if (
                                event.key === Qt.Key_Return ||
                                event.key === Qt.Key_Enter ||
                                event.key === Qt.Key_Space
                            ) {
                                root.applyTheme(root.selectedIndex)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                root.open = false
                                event.accepted = true
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            spacing: 4

                            Repeater {
                                model: root.themeModel

                                delegate: Rectangle {
                                    id: pill

                                    required property var modelData
                                    required property int index

                                    readonly property bool selected:
                                        root.selectedIndex === index

                                    width: (parent.width - 16) / 5
                                    height: 32
                                    radius: 8

                                    color: selected
                                        ? root.colors.cSelection
                                        : "transparent"

                                    border.width: 1
                                    border.color: selected
                                        ? Qt.alpha(modelData.accent, 0.3)
                                        : "transparent"

                                    Behavior on color {
                                        ColorAnimation { duration: 120 }
                                    }

                                    Behavior on border.color {
                                        ColorAnimation { duration: 120 }
                                    }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 8

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 8
                                            height: 8
                                            radius: 4
                                            color: modelData.accent
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.name
                                            width: Math.max(0, pill.width - 40)
                                            elide: Text.ElideRight
                                            color: pill.selected
                                                ? root.colors.cText
                                                : root.colors.cMuted
                                            font.pixelSize: 11
                                            font.family: "sans-serif"
                                            font.weight: pill.selected
                                                ? Font.DemiBold
                                                : Font.Medium
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true

                                        onEntered: root.selectedIndex = index
                                        onClicked: root.applyTheme(index)
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


import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    required property var colors
    property bool open: false
    property bool alive: false

    IpcHandler {
        target: "workspaceoverview"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
    }

    onOpenChanged: {
        if (open) {
            alive = true
            closeTimer.stop()
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: 180
        onTriggered: root.alive = false
    }

    LazyLoader {
        active: root.alive

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            Rectangle {
                id: card
                width: Math.min(900, parent.width - 32)
                height: Math.min(620, parent.height - 32)
                anchors.centerIn: parent
                radius: 16
                color: root.colors.cSurface
                border.width: 1
                border.color: Qt.alpha(root.colors.cBorder, 0.7)
                opacity: root.open ? 1 : 0
                scale: root.open ? 1 : 0.98

                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150 } }

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Espaces de travail"
                            color: root.colors.cText
                            font.pixelSize: 17
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Échap pour fermer"
                            color: root.colors.cMuted
                            font.pixelSize: 11
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: parent.width < 660 ? 2 : 4
                        columnSpacing: 10
                        rowSpacing: 10

                        Repeater {
                            model: Array.from({ length: 10 }, (_, i) => i + 1)

                            delegate: Rectangle {
                                required property int modelData
                                readonly property int workspaceId: modelData
                                readonly property var windows: Hyprland.toplevels.values
                                    .filter(window => window.workspace?.id === workspaceId)

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 100
                                radius: 10
                                color: Hyprland.focusedWorkspace?.id === workspaceId
                                    ? root.colors.cSelection : root.colors.cElevated
                                border.width: Hyprland.focusedWorkspace?.id === workspaceId ? 1 : 0
                                border.color: Qt.alpha(root.colors.cAccent, 0.5)

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "Workspace " + workspaceId
                                            color: root.colors.cText
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: windows.length
                                            color: root.colors.cMuted
                                            font.pixelSize: 11
                                        }
                                        Rectangle {
                                            implicitWidth: 40
                                            implicitHeight: 22
                                            radius: 5
                                            color: overviewMouse.containsMouse ? root.colors.cSurface : "transparent"
                                            Text { anchors.centerIn: parent; text: "Ouvrir"; color: root.colors.cAccent; font.pixelSize: 9 }
                                            MouseArea {
                                                id: overviewMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: {
                                                    Hyprland.dispatch("workspace " + workspaceId)
                                                    root.open = false
                                                }
                                            }
                                        }
                                    }

                                    Repeater {
                                        model: windows.slice(0, 4)
                                        delegate: Text {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            text: modelData.title || modelData.lastIpcObject?.class || "Fenêtre"
                                            color: root.colors.cMuted
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    const address = modelData.address.startsWith("0x")
                                                        ? modelData.address : "0x" + modelData.address
                                                    Hyprland.dispatch("focuswindow address:" + address)
                                                    root.open = false
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: windows.length === 0
                                        text: "Vide"
                                        color: root.colors.cMuted
                                        font.pixelSize: 11
                                    }
                                }

                            }
                        }
                    }
                }

                Keys.onEscapePressed: root.open = false
                focus: root.open
            }
        }
    }
}

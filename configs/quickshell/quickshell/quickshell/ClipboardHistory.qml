import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    required property var colors
    property bool open: false
    property bool alive: false
    property bool available: false
    property var entries: []
    property var sessionEntries: []

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            const value = Quickshell.clipboardText
            if (!value || value.trim() === "") return
            root.sessionEntries = [{ id: String(Date.now()), preview: value.slice(0, 200), value: value }]
                .concat(root.sessionEntries.filter(item => item.value !== value)).slice(0, 40)
            if (!root.available) root.entries = root.sessionEntries
        }
    }

    function refresh() {
        availabilityProc.running = true
        if (available)
            historyProc.running = true
    }

    function copyEntry(id) {
        if (!available) {
            const entry = entries.find(item => item.id === id)
            if (entry) Quickshell.clipboardText = entry.value
            root.open = false
            return
        }
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "qs-clipboard", id])
        root.open = false
    }

    function copySelected() {
        if (list.currentItem)
            root.copyEntry(list.currentItem.modelData.id)
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            root.open = !root.open
            if (root.open) root.refresh()
        }
        function show(): void { root.open = true; root.refresh() }
        function hide(): void { root.open = false }
    }

    Process {
        id: availabilityProc
        command: ["sh", "-c", "command -v cliphist >/dev/null && command -v wl-copy >/dev/null && command -v wl-paste >/dev/null && echo yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = text.trim() === "yes"
                if (root.available) {
                    historyProc.running = true
                    if (!clipboardWatcher.running) clipboardWatcher.running = true
                }
                else root.entries = root.sessionEntries
            }
        }
    }

    Process {
        id: clipboardWatcher
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
    }

    Component.onCompleted: availabilityProc.running = true

    Process {
        id: historyProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(line => line.trim() !== "")
                    .map(line => {
                        const separator = line.indexOf("\t")
                        return {
                            id: separator >= 0 ? line.slice(0, separator) : line,
                            preview: separator >= 0 ? line.slice(separator + 1) : line
                        }
                    }).slice(0, 40)
            }
        }
    }

    onOpenChanged: {
        if (open) {
            alive = true
            closeTimer.stop()
            refresh()
        } else closeTimer.restart()
    }

    Timer {
        id: closeTimer
        interval: 160
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

            MouseArea { anchors.fill: parent; onClicked: root.open = false }

            Rectangle {
                id: card
                width: Math.min(520, parent.width - 32)
                height: Math.min(600, parent.height - 32)
                anchors.centerIn: parent
                radius: 14
                color: root.colors.cSurface
                border.width: 1
                border.color: Qt.alpha(root.colors.cBorder, 0.7)
                opacity: root.open ? 1 : 0
                scale: root.open ? 1 : 0.98
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150 } }

                MouseArea { anchors.fill: parent }
                Keys.onEscapePressed: root.open = false
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Up) {
                        list.decrementCurrentIndex()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        list.incrementCurrentIndex()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.copySelected()
                        event.accepted = true
                    }
                }
                focus: root.open

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Presse-papiers"
                            color: root.colors.cText
                            font.pixelSize: 16
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.entries.length + (root.available ? " éléments" : " · shell")
                            color: root.colors.cMuted
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: !root.available && root.entries.length === 0
                        text: "Les copies faites depuis ce shell apparaissent ici. Pour suivre le presse-papiers des autres applications, installe cliphist et wl-clipboard."
                        color: root.colors.cMuted
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.available && root.entries.length === 0
                        text: "Aucun élément dans l’historique."
                        color: root.colors.cMuted
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.entries.length > 0
                        clip: true
                        spacing: 5
                        currentIndex: 0
                        model: root.entries
                        delegate: Rectangle {
                            required property var modelData
                            width: list.width
                            height: 48
                            radius: 8
                            color: ListView.isCurrentItem || rowMouse.containsMouse
                                ? root.colors.cSelection : "transparent"
                            Text {
                                anchors.fill: parent
                                anchors.margins: 10
                                text: modelData.preview
                                color: root.colors.cText
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.copyEntry(modelData.id)
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "↑↓ parcourir · Entrée copier · Échap fermer"
                        color: root.colors.cMuted
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}

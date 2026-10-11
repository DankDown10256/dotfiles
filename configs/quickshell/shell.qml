import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    // --- palette ---
    readonly property color bg: "#11111b"
    readonly property color fg: "#cdd6f4"
    readonly property color dim: "#585b70"
    readonly property color accent: "#89b4fa"
    readonly property color warn: "#f38ba8"

    // --- audio ---
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: sink?.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink?.audio ? sink.audio.muted : false
    PwObjectTracker { objects: [root.sink] }

    // --- wifi (nmcli, polling) ---
    property bool wifiUp: false
    property int wifiSignal: 0
    Process {
        id: wifiProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SSID", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n").find(l => l.startsWith("*:"));
                if (!line) { root.wifiUp = false; return; }
                root.wifiUp = true;
                root.wifiSignal = parseInt(line.split(":")[1]) || 0;
            }
        }
    }
    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: wifiProc.running = true
    }

    // --- brightness (brightnessctl) ---
    property int brightness: 0
    Process {
        id: briProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",");
                if (p.length >= 4) root.brightness = parseInt(p[3]) || 0;
            }
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: briProc.running = true
    }

    // --- horloge ---
    SystemClock { id: clock; precision: SystemClock.Minutes }

    // --- media ---
    readonly property var player: {
        const l = Mpris.players.values;
        return l.find(p => p.isPlaying) ?? l[0] ?? null;
    }

    // icône générique
    component Ico: Text {
        color: root.fg
        font.pixelSize: 16
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true }
            implicitWidth: 48
            exclusiveZone: implicitWidth
            color: root.bg

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: 12

                // ---------- workspaces ----------
                Repeater {
                    model: 5
                    Rectangle {
                        id: ws
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property bool focused: Hyprland.focusedWorkspace?.id === wsId
                        readonly property bool exists: Hyprland.workspaces.values.some(w => w.id === wsId)

                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 28; implicitHeight: 28
                        radius: 8
                        color: focused ? root.accent : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: ws.wsId
                            font.pixelSize: 13
                            font.bold: ws.focused
                            color: ws.focused ? root.bg : (ws.exists ? root.fg : root.dim)
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Hyprland.dispatch("workspace " + ws.wsId)
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // ---------- media ----------
                ColumnLayout {
                    visible: root.player !== null
                    spacing: 8
                    Layout.alignment: Qt.AlignHCenter

                    Ico {
                        text: "\uf048"
                        color: root.player?.canGoPrevious ? root.fg : root.dim
                        MouseArea { anchors.fill: parent; onClicked: root.player?.previous() }
                    }
                    Ico {
                        text: root.player?.isPlaying ? "\uf04c" : "\uf04b"
                        color: root.accent
                        MouseArea { anchors.fill: parent; onClicked: root.player?.togglePlaying() }
                    }
                    Ico {
                        text: "\uf051"
                        color: root.player?.canGoNext ? root.fg : root.dim
                        MouseArea { anchors.fill: parent; onClicked: root.player?.next() }
                    }
                }

                Item { Layout.fillHeight: true }

                // ---------- tray ----------
                Repeater {
                    model: SystemTray.items
                    MouseArea {
                        id: trayItem
                        required property var modelData
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 20; implicitHeight: 20
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                                modelData.activate();
                            } else if (modelData.hasMenu) {
                                const p = mapToItem(null, mouse.x, mouse.y);
                                modelData.display(bar, p.x, p.y);
                            }
                        }

                        IconImage {
                            anchors.fill: parent
                            source: trayItem.modelData.icon
                        }
                    }
                }

                // ---------- wifi ----------
                Ico {
                    text: "\uf1eb"
                    color: !root.wifiUp ? root.dim : (root.wifiSignal < 30 ? root.warn : root.fg)
                }

                // ---------- son ----------
                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignHCenter
                    Ico {
                        text: root.muted ? "\uf6a9" : "\uf028"
                        color: root.muted ? root.warn : root.fg
                    }
                    Text {
                        text: root.volume
                        color: root.fg
                        font.pixelSize: 10
                        Layout.alignment: Qt.AlignHCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
                        onWheel: wheel => {
                            if (!root.sink?.audio) return;
                            const d = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + d));
                        }
                    }
                }

                // ---------- brightness ----------
                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignHCenter
                    Ico { text: "\uf185" }
                    Text {
                        text: root.brightness
                        color: root.fg
                        font.pixelSize: 10
                        Layout.alignment: Qt.AlignHCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        onWheel: wheel => {
                            Quickshell.execDetached(["brightnessctl", "set", wheel.angleDelta.y > 0 ? "5%+" : "5%-"]);
                            briProc.running = true;
                        }
                    }
                }

                // ---------- heure ----------
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: root.fg
                    font.pixelSize: 13
                    font.bold: true
                    text: Qt.formatDateTime(clock.date, "HH") + "\n" + Qt.formatDateTime(clock.date, "mm")
                }
            }
        }
    }
}

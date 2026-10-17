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

    Launcher {}

    ControlCenter {
        id: controlCenter
    }

    // --- palette ---
    readonly property color bg: "#0d1117"
    readonly property color fg: "#e6edf3"
    readonly property color dim: "#7d8590"
    readonly property color accent: "#58a6ff"
    readonly property color warn: "#f85149"
    readonly property string font: "Iosevka Nerd Font"

    // --- audio ---
    property int volume: 0
    property bool muted: false

    Process {
        id: audioReader
        command: ["env", "LC_ALL=C", "sh", "-c",
            "pactl get-sink-volume @DEFAULT_SINK@; pactl get-sink-mute @DEFAULT_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const vol = text.match(/(\d+)%/)
                if (vol) root.volume = parseInt(vol[1])
                const mute = text.match(/Mute:\s*(yes|no)/)
                if (mute) root.muted = mute[1] === "yes"
            }
        }
    }

    Timer {
        id: audioDebounce
        interval: 50
        onTriggered: if (!audioReader.running) audioReader.running = true
    }

    Process {
        running: true
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            onRead: data => {
                if (data.includes("sink") || data.includes("server"))
                    audioDebounce.restart()
            }
        }
    }

    Component.onCompleted: audioReader.running = true

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

    // --- batterie (sysfs, polling) ---
    property bool batPresent: false
    property int batPercent: 0
    property bool batCharging: false
    Process {
        id: batProc
        command: ["sh", "-c",
            "cat /sys/class/power_supply/BAT0/capacity /sys/class/power_supply/BAT0/status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                if (l.length < 2) { root.batPresent = false; return; }
                root.batPresent = true;
                root.batPercent = parseInt(l[0]) || 0;
                root.batCharging = l[1] === "Charging";
            }
        }
    }
    Timer {
        interval: 10000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: batProc.running = true
    }
    function batIcon() {
        if (batCharging) return "\uf0e7";
        if (batPercent > 85) return "\uf240";
        if (batPercent > 60) return "\uf241";
        if (batPercent > 35) return "\uf242";
        if (batPercent > 10) return "\uf243";
        return "\uf244";
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
        font.family: root.font
        verticalAlignment: Text.AlignVCenter
        Layout.alignment: Qt.AlignVCenter
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            anchors { bottom: true; left: true; right: true }
            implicitHeight: 35
            exclusiveZone: implicitHeight
            color: root.bg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
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

                        Layout.alignment: Qt.AlignVCenter
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

                // ---------- titre fenêtre active (centré) ----------
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width)
                        visible: text.length > 0
                        text: Hyprland.focusedWindow ? Hyprland.focusedWindow.title : ""
                        font.pixelSize: 12
                        font.bold: true
                        font.family: root.font
                        color: root.dim
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // ---------- media ----------
                RowLayout {
                    visible: root.player !== null
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

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

                // ---------- tray ----------
                Repeater {
                    model: SystemTray.items
                    MouseArea {
                        id: trayItem
                        required property var modelData
                        Layout.alignment: Qt.AlignVCenter
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
                Item {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: soundRow.implicitWidth
                    implicitHeight: soundRow.implicitHeight

                    RowLayout {
                        id: soundRow
                        spacing: 4
                        Ico {
                            text: root.muted ? "\uf6a9" : "\uf028"
                            color: root.muted ? root.warn : root.fg
                        }
                        Text {
                            text: root.volume
                            color: root.fg
                            font.family: root.font
                            font.pixelSize: 12
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
                        onWheel: wheel => {
                            const d = wheel.angleDelta.y > 0 ? "+5%" : "-5%";
                            Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", d]);
                            audioDebounce.restart();
                        }
                    }
                }

                // ---------- luminosité ----------
                Item {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: briRow.implicitWidth
                    implicitHeight: briRow.implicitHeight

                    RowLayout {
                        id: briRow
                        spacing: 4
                        Ico { text: "\uf185" }
                        Text {
                            text: root.brightness
                            color: root.fg
                            font.family: root.font
                            font.pixelSize: 12
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onWheel: wheel => {
                            Quickshell.execDetached(["brightnessctl", "set", wheel.angleDelta.y > 0 ? "5%+" : "5%-"]);
                            briProc.running = true;
                        }
                    }
                }

                // ---------- batterie ----------
                RowLayout {
                    visible: root.batPresent
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    readonly property bool low: root.batPercent <= 15 && !root.batCharging

                    Ico {
                        text: root.batIcon()
                        color: parent.low ? root.warn : (root.batCharging ? root.accent : root.fg)
                    }
                    Text {
                        text: root.batPercent + "%"
                        color: parent.low ? root.warn : root.fg
                        font.family: root.font
                        font.pixelSize: 12
                    }
                }

                // ---------- heure ----------
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    color: root.fg
                    font.pixelSize: 13
                    font.family: root.font
                    font.bold: true
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                }
            }
        }
    }
}

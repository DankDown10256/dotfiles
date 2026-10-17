import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

Scope {
    id: root

    property bool open: false
    property bool alive: false

    readonly property color colBg: "#0d1117"
    readonly property color colSurface: "#161b22"
    readonly property color colSelection: "#1f6feb80"
    readonly property color colAccent: "#58a6ff"
    readonly property color colText: "#e6edf3"
    readonly property color colMuted: "#7d8590"
    readonly property color colDanger: "#f85149"
    
    property int pomoMinutes: 25
    property int pomoSeconds: 0
    property bool pomoRunning: false
    property bool pomoIsWork: true

    property bool dndActive: false

    property bool aiActive: false
    property string aiToolName: ""
    property int aiCount: 0
    readonly property var aiTools: ({ claude: "Claude", opencode: "OpenCode", codex: "Codex" })

    property int brightness: 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: sink?.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink?.audio ? sink.audio.muted : false

    PwObjectTracker { objects: [root.sink] }

    onOpenChanged: {
        if (open) {
            alive = true
            closeTimer.stop()
        } else {
            closeTimer.restart()
        }
    }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { root.open = !root.open }
    }

    QtObject {
        id: wifiInfo
        property string ssid: "Non connecté"
    }

    QtObject {
        id: userInfo
        property string username: "dev"
    }

    Process {
        id: userProc
        running: true
        command: ["whoami"]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() !== "") userInfo.username = data.trim()
            }
        }
    }

    Process {
        id: wifiProc
        command: ["nmcli", "-t", "-f", "active,ssid", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n").find(l => l.startsWith("oui:"))
                wifiInfo.ssid = line ? line.substring(4) : "Non connecté"
            }
        }
    }

    Process {
        id: briProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",")
                if (p.length >= 4) root.brightness = parseInt(p[3]) || 0
            }
        }
    }

    Process {
        id: aiDetectorProc
        command: ["ps", "-eo", "comm=,args="]
        stdout: StdioCollector {
            onStreamFinished: {
                const base = s => (s ?? "").split("/").pop().replace(/\.js$/, "")
                const names = []
                for (const line of text.split("\n")) {
                    const t = line.trim().split(/\s+/)
                    for (const c of [t[0], base(t[1]), base(t[2])]) {
                        if (root.aiTools.hasOwnProperty(c) && !names.includes(root.aiTools[c]))
                            names.push(root.aiTools[c])
                    }
                    if (line.startsWith("Vibe CLI") && !names.includes("Mistral Vibe"))
                        names.push("Mistral Vibe")
                }
                root.aiActive = names.length > 0
                root.aiToolName = names.join(", ")
                root.aiCount = names.length
            }
        }
    }

    Timer {
        interval: 3000
        running: root.alive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiProc.running = true
            briProc.running = true
            aiDetectorProc.running = true
        }
    }

    Timer {
        id: pomoTimer
        interval: 1000
        repeat: true
        running: root.pomoRunning
        onTriggered: {
            if (root.pomoSeconds > 0) {
                root.pomoSeconds--
            } else if (root.pomoMinutes > 0) {
                root.pomoMinutes--
                root.pomoSeconds = 59
            } else {
                root.pomoIsWork = !root.pomoIsWork
                root.pomoMinutes = root.pomoIsWork ? 25 : 5
                root.pomoSeconds = 0
                root.pomoRunning = false
                Quickshell.execDetached(["notify-send", root.pomoIsWork ? "Pause terminée !" : "Pomodoro terminé !", "Temps de changer d'activité."])
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 420
        onTriggered: root.alive = false
    }

    LazyLoader {
        active: root.alive

        PanelWindow {
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            Rectangle {
                id: card
                width: 420
                height: 610
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.top: parent.top
                anchors.topMargin: shown ? 16 : -(height + 20)

                color: root.colBg
                radius: 28
                border.color: root.colSelection
                border.width: 1

                property bool shown: false
                opacity: shown ? 1 : 0

                Component.onCompleted: Qt.callLater(() => shown = root.open)
                Connections {
                    target: root
                    function onOpenChanged() { card.shown = root.open }
                }

                Behavior on anchors.topMargin {
                    NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: userInfo.username
                            font.pixelSize: 16
                            font.bold: true
                            color: root.colAccent
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            id: clockText
                            font.pixelSize: 15
                            font.bold: true
                            color: root.colText

                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                triggeredOnStart: true
                                onTriggered: {
                                    let d = new Date()
                                    clockText.text = d.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 45
                        color: root.colSurface
                        radius: 10
                        visible: root.aiActive
                        border.color: root.colAccent
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Text {
                                text: "\uF121"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                color: root.colAccent
                            }

                            Text {
                                text: root.aiToolName + (root.aiCount > 1 ? " sont" : " est") + " en train de travailler..."
                                font.pixelSize: 12
                                font.bold: true
                                color: root.colText
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            color: root.dndActive ? root.colAccent : root.colSurface
                            radius: 12

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: "\uF1F8"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    color: root.dndActive ? root.colBg : root.colText
                                }
                                Text {
                                    text: root.dndActive ? "DND Actif" : "Silence"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.dndActive ? root.colBg : root.colText
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.dndActive = !root.dndActive
                                    Quickshell.execDetached(["dunstctl", "set-paused", root.dndActive ? "true" : "false"])
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            color: root.colSurface
                            radius: 12

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: "\uF2F2"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    color: root.pomoRunning ? root.colAccent : root.colMuted
                                }
                                Text {
                                    text: (root.pomoMinutes < 10 ? "0" : "") + root.pomoMinutes + ":" + (root.pomoSeconds < 10 ? "0" : "") + root.pomoSeconds
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.colText
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.pomoRunning = !root.pomoRunning
                                onDoubleClicked: {
                                    root.pomoRunning = false
                                    root.pomoIsWork = true
                                    root.pomoMinutes = 25
                                    root.pomoSeconds = 0
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 65
                        color: root.colSurface
                        radius: 12

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: root.pomoIsWork ? "Session de Focus" : "Pause Café"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.colText
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: root.pomoRunning ? "En cours (Double-clic pour reset)" : "En pause"
                                    font.pixelSize: 10
                                    color: root.colMuted
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                color: root.colSelection
                                radius: 3

                                Rectangle {
                                    readonly property real totalSec: (root.pomoIsWork ? 25 : 5) * 60
                                    readonly property real currentSec: (root.pomoMinutes * 60) + root.pomoSeconds
                                    width: parent.width * (1.0 - (currentSec / totalSec))
                                    height: parent.height
                                    color: root.colAccent
                                    radius: 3

                                    Behavior on width {
                                        NumberAnimation { duration: 200 }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        color: root.colSurface
                        radius: 12

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Text {
                                text: "\uF1EB"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20
                                color: root.colAccent
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true

                                Text {
                                    text: "RÉSEAU WI-FI"
                                    font.pixelSize: 9
                                    color: root.colMuted
                                }

                                Text {
                                    text: wifiInfo.ssid
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.colText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 55
                        color: root.colSurface
                        radius: 12

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Text {
                                text: root.muted ? "\uF6A9" : "\uF028"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: root.muted ? root.colDanger : root.colAccent
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Volume"; font.pixelSize: 11; color: root.colText }
                                    Item { Layout.fillWidth: true }
                                    Text { text: root.volume + "%"; font.pixelSize: 10; color: root.colMuted }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 5
                                    color: root.colSelection
                                    radius: 3

                                    Rectangle {
                                        width: parent.width * Math.min(1, root.volume / 100)
                                        height: parent.height
                                        color: root.muted ? root.colDanger : root.colAccent
                                        radius: 3
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 55
                        color: root.colSurface
                        radius: 12

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Text {
                                text: "\uF185"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: root.colAccent
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Luminosité"; font.pixelSize: 11; color: root.colText }
                                    Item { Layout.fillWidth: true }
                                    Text { text: root.brightness + "%"; font.pixelSize: 10; color: root.colMuted }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 5
                                    color: root.colSelection
                                    radius: 3

                                    Rectangle {
                                        width: parent.width * Math.min(1, root.brightness / 100)
                                        height: parent.height
                                        color: root.colAccent
                                        radius: 3
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: root.colSurface
                            radius: 10
                            Text {
                                anchors.centerIn: parent
                                text: "\uF023"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: root.colText
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["hyprlock"])
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: root.colSurface
                            radius: 10
                            Text {
                                anchors.centerIn: parent
                                text: "\uF08B"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: root.colText
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: root.colSurface
                            radius: 10
                            Text {
                                anchors.centerIn: parent
                                text: "\uF01E"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: root.colText
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: root.colDanger
                            radius: 10
                            Text {
                                anchors.centerIn: parent
                                text: "\uF011"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: root.colBg
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                            }
                        }
                    }
                }
            }
        }
    }
}

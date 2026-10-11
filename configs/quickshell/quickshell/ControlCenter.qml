import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

Scope {
    id: root

    property bool alive: false

    // Palette Claude
    readonly property color colBg: "#1f1a17"
    readonly property color colSurface: "#2d241f"
    readonly property color colSelection: "#43302580"
    readonly property color colAccent: "#d97757"
    readonly property color colText: "#f0e6d8"
    readonly property color colMuted: "#a08b7a"
    readonly property color colDanger: "#e5534b"

    // --- State Pomodoro ---
    property int pomoMinutes: 25
    property int pomoSeconds: 0
    property bool pomoRunning: false
    property bool pomoIsWork: true

    // --- State DND ---
    property bool dndActive: false

    // --- State AI Dev Detector ---
    property bool aiActive: false
    property string aiToolName: ""

    IpcHandler {
        target: "controlcenter"
        function toggle() {
            if (root.alive) {
                closeTimer.restart()
                root.alive = false
            } else {
                panelLoader.active = true
                root.alive = true
                closeTimer.stop()
            }
        }
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
        running: true
        command: ["nmcli", "-t", "-f", "active,ssid", "dev", "wifi"]
        stdout: SplitParser {
            onRead: data => {
                let lines = data.split("\n")
                for (let line of lines) {
                    if (line.startsWith("yes:")) {
                        wifiInfo.ssid = line.substring(4)
                        break
                    }
                }
            }
        }
    }

    // Détection des outils de dev IA (opencode, claude, codex)
    Process {
        id: aiDetectorProc
        command: ["sh", "-c", "pgrep -af 'opencode|claude|codex' || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                let output = text.trim()
                if (output.length > 0) {
                    root.aiActive = true
                    if (output.includes("opencode")) root.aiToolName = "Opencode"
                    else if (output.includes("claude")) root.aiToolName = "Claude Code"
                    else if (output.includes("codex")) root.aiToolName = "Codex"
                    else root.aiToolName = "Assistant IA"
                } else {
                    root.aiActive = false
                    root.aiToolName = ""
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: aiDetectorProc.running = true
    }

    QtObject {
        id: wifiInfo
        property string ssid: "Non connecté"
    }

    QtObject {
        id: userInfo
        property string username: "dev"
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
        interval: 380
        running: false
        onTriggered: panelLoader.active = false
    }

    LazyLoader {
        id: panelLoader
        active: root.alive

        PanelWindow {
            id: panel
            width: 420
            height: 610

            anchors {
                bottom: true
                right: true
            }

            margins {
                right: root.alive ? 16 : -440
                bottom: root.alive ? 16 : -630
            }

            color: "transparent"
            focusable: root.alive

            Behavior on margins.right {
                NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
            }
            Behavior on margins.bottom {
                NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
            }

            Rectangle {
                anchors.fill: parent
                color: root.colBg
                topLeftRadius: 28
                bottomLeftRadius: 28
                topRightRadius: 28
                bottomRightRadius: 0
                border.color: root.colSelection
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    // ---------- Header ----------
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

                    // ---------- Widget Détection IA (Conditionnel) ----------
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
                                text: "\uF121" // Code bracket
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                color: root.colAccent
                            }

                            Text {
                                text: root.aiToolName + " est en train de travailler..."
                                font.pixelSize: 12
                                font.bold: true
                                color: root.colText
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // ---------- Ligne DND & Pomodoro Quick Controls ----------
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
                                // Double-clic pour réinitialiser le pomodoro à 25:00
                                onDoubleClicked: {
                                    root.pomoRunning = false
                                    root.pomoIsWork = true
                                    root.pomoMinutes = 25
                                    root.pomoSeconds = 0
                                }
                            }
                        }
                    }

                    // ---------- Carte Pomodoro Détaillée ----------
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

                    // ---------- Carte Wifi ----------
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

                    // ---------- Audio ----------
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
                                        width: parent.width * (root.volume / 100)
                                        height: parent.height
                                        color: root.muted ? root.colDanger : root.colAccent
                                        radius: 3
                                    }
                                }
                            }
                        }
                    }

                    // ---------- Luminosité ----------
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
                                        width: parent.width * (root.brightness / 100)
                                        height: parent.height
                                        color: root.colAccent
                                        radius: 3
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // ---------- Footer System Actions ----------
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

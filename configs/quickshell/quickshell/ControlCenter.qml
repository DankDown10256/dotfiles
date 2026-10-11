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
    property bool pomoIsWork: true // true = Focus, false = Pause

    // --- State DND ---
    property bool dndActive: false

    // IPC Handler pour Hyprland
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

    // Utilisateur
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

    // Wifi
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

    QtObject {
        id: wifiInfo
        property string ssid: "Non connecté"
    }

    QtObject {
        id: userInfo
        property string username: "dev"
    }

    // Timer du Pomodoro
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
                // Fin de session
                root.pomoIsWork = !root.pomoIsWork
                root.pomoMinutes = root.pomoIsWork ? 25 : 5
                root.pomoSeconds = 0
                root.pomoRunning = false
                Quickshell.execDetached(["notify-send", root.pomoIsWork ? "Pause terminée !" : "Pomodoro terminé !", "Temps de changer d'activité."])
            }
        }
    }

    // Timer de fermeture pour la transition de sortie
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
            height: 560

            anchors {
                bottom: true
                right: true
            }

            margins {
                right: root.alive ? 16 : -440
                bottom: root.alive ? 16 : -580
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

                    // ---------- Ligne DND & Pomodoro Quick Controls ----------
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Button DND
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            color: root.dndActive ? root.colAccent : root.colSurface
                            radius: 12

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: "\uF1F8" // Bell Slash
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
                                    // Commande dnd externe (dunstctl / swaync)
                                    Quickshell.execDetached(["dunstctl", "set-paused", root.dndActive ? "true" : "false"])
                                }
                            }
                        }

                        // Status Pomodoro
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            color: root.colSurface
                            radius: 12

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: "\uF2F2" // Timer icon
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
                                    text: root.pomoRunning ? "En cours" : "En pause"
                                    font.pixelSize: 10
                                    color: root.colMuted
                                }
                            }

                            // Barre de progression Pomodoro
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

                        // Verrouiller
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: root.colSurface
                            radius: 10
                            Text {
                                anchors.centerIn: parent
                                text: "\uF023" // Lock
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: root.colText
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["hyprlock"])
                            }
                        }

                        // Déconnexion
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: root.colSurface
                            radius: 10
                            Text {
                                anchors.centerIn: parent
                                text: "\uF08B" // Logout
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: root.colText
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
                            }
                        }

                        // Redémarrer
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: root.colSurface
                            radius: 10
                            Text {
                                anchors.centerIn: parent
                                text: "\uF01E" // Reboot
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: root.colText
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                            }
                        }

                        // Éteindre
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: root.colDanger
                            radius: 10
                            Text {
                                anchors.centerIn: parent
                                text: "\uF011" // Power off
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

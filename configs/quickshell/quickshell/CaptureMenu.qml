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
    property bool grimAvailable: false
    property bool slurpAvailable: false
    property bool recorderAvailable: false
    readonly property bool recording: recorderProc.running

    function timestamp() {
        return Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss")
    }

    function takeScreenshot(kind) {
        if (!root.grimAvailable || (kind === "region" && !root.slurpAvailable)) {
            root.open = true
            availabilityProc.running = true
            return
        }
        const stamp = timestamp()
        const path = '"$HOME/Pictures/Screenshots/qs-' + stamp + '.png"'
        const geometry = kind === "region" ? '"$(slurp)"'
            : kind === "window" ? '"$(hyprctl activewindow -j | jq -r \'"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])"\')"' : ""
        const script = 'mkdir -p "$HOME/Pictures/Screenshots" && grim '
            + (geometry ? '-g ' + geometry + ' ' : '') + path
        Quickshell.execDetached(["sh", "-c", script])
        root.open = false
    }

    function toggleRecording() {
        if (recorderProc.running) {
            recorderProc.signal(2)
            return
        }
        if (!recorderAvailable) {
            root.open = true
            availabilityProc.running = true
            return
        }
        recorderProc.command = ["sh", "-c",
            "mkdir -p \"$HOME/Videos\" && exec wf-recorder -f \"$1\"",
            "qs-recording", Quickshell.env("HOME") + "/Videos/qs-" + timestamp() + ".mp4"]
        recorderProc.running = true
        root.open = false
    }

    IpcHandler {
        target: "capture"
        function toggle(): void {
            root.open = !root.open
            if (root.open) availabilityProc.running = true
        }
        function show(): void { root.open = true; availabilityProc.running = true }
        function hide(): void { root.open = false }
        function region(): void { root.takeScreenshot("region") }
        function window(): void { root.takeScreenshot("window") }
        function screen(): void { root.takeScreenshot("screen") }
        function record(): void { root.toggleRecording() }
    }

    Process {
        id: availabilityProc
        command: ["sh", "-c", "command -v grim >/dev/null && echo grim; command -v slurp >/dev/null && echo slurp; command -v wf-recorder >/dev/null && echo wf-recorder"]
        stdout: StdioCollector {
            onStreamFinished: {
                const installed = text.split("\n").map(item => item.trim())
                root.grimAvailable = installed.includes("grim")
                root.slurpAvailable = installed.includes("slurp")
                root.recorderAvailable = installed.includes("wf-recorder")
            }
        }
    }

    Process { id: recorderProc }
    Component.onCompleted: availabilityProc.running = true

    onOpenChanged: {
        if (open) {
            alive = true
            closeTimer.stop()
            availabilityProc.running = true
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
                width: Math.min(440, parent.width - 32)
                height: Math.min(340, parent.height - 32)
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
                focus: root.open

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    Text {
                        text: "Capture"
                        color: root.colors.cText
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Repeater {
                        model: [
                            { title: "Capture écran", detail: root.grimAvailable ? "Enregistrer dans Images/Screenshots" : "grim indisponible", enabled: root.grimAvailable },
                            { title: "Sélectionner une région", detail: root.grimAvailable && root.slurpAvailable ? "Choisir une zone à capturer" : "grim ou slurp indisponible", enabled: root.grimAvailable && root.slurpAvailable },
                            { title: "Fenêtre active", detail: root.grimAvailable ? "Capturer uniquement la fenêtre au focus" : "grim indisponible", enabled: root.grimAvailable },
                            { title: recorderProc.running ? "Arrêter l’enregistrement" : "Enregistrer l’écran", detail: root.recorderAvailable ? "wf-recorder · dossier Vidéos" : "wf-recorder indisponible", enabled: root.recorderAvailable || recorderProc.running }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredHeight: 62
                            radius: 8
                            color: captureMouse.containsMouse
                                ? root.colors.cSelection : root.colors.cElevated
                            opacity: modelData.enabled ? 1 : 0.55
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 3
                                Text { text: modelData.title; color: root.colors.cText; font.pixelSize: 12; font.bold: true }
                                Text { text: modelData.detail; color: root.colors.cMuted; font.pixelSize: 10 }
                            }
                            MouseArea {
                                id: captureMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: modelData.enabled
                                onClicked: {
                                    if (index === 0) root.takeScreenshot("screen")
                                    else if (index === 1) root.takeScreenshot("region")
                                    else if (index === 2) root.takeScreenshot("window")
                                    else root.toggleRecording()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

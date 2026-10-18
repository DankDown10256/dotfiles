import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Wayland

Scope {
    id: root

    property bool open: false
    property bool alive: false

    
    readonly property color colBg:        colors.cBg
    readonly property color colSurface:   colors.cSurface
    readonly property color colSelection: colors.cSelection
    readonly property color colAccent:    colors.cAccent
    readonly property color colText:      colors.cText
    readonly property color colMuted:     colors.cMuted
    readonly property color colDanger:    colors.cDanger
    readonly property color colSuccess:   colors.cSuccess
    readonly property color colWarning:   colors.cWarning
    
    property int pomoMinutes: 25
    property int pomoSeconds: 0
    property bool pomoRunning: false
    property bool pomoIsWork: true

    required property var colors
    property int barInset: 32

    property var notifications: null
    readonly property bool dndActive: notifications?.dnd ?? false

    property bool aiActive: false
    property string aiToolName: ""
    property int aiCount: 0
    readonly property var aiTools: ({ claude: "Claude", opencode: "OpenCode", codex: "Codex" })

    property int brightness: 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: sink?.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink?.audio ? sink.audio.muted : false

    PwObjectTracker { objects: [root.sink] }

    readonly property var player: {
        const players = Mpris.players.values
        return players.find(p => p.isPlaying) ?? players[0] ?? null
    }

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
        interval: 240
        onTriggered: root.alive = false
    }

    Timer {
        id: brightnessWriter
        interval: 80
        onTriggered: brightnessSet.running = true
    }

    Process {
        id: brightnessSet
        command: ["brightnessctl", "set", root.brightness + "%"]
    }

    LazyLoader {
        active: root.alive

        PanelWindow {
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            Rectangle {
                id: card
                width: Math.min(880, parent.width - 32)
                height: Math.min(
                    controlsContent.implicitHeight + 56,
                    parent.height
                )
                anchors.horizontalCenter: parent.horizontalCenter
                y: -24

                color: root.colSurface
                radius: 24
                border.width: 1
                border.color: Qt.alpha(root.colors.cBorder, 0.65)

                transform: Translate {
                    y: card.shown ? 0 : -card.height

                    Behavior on y {
                        NumberAnimation {
                            duration: card.shown ? 320 : 220
                            easing.type: card.shown
                                ? Easing.OutQuint : Easing.InCubic
                        }
                    }
                }

                property bool shown: false
                opacity: shown ? 1 : 0

                Component.onCompleted: Qt.callLater(() => shown = root.open)
                Connections {
                    target: root
                    function onOpenChanged() { card.shown = root.open }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: card.shown ? 180 : 200
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea { anchors.fill: parent }

                Item {
                    anchors.fill: parent
                    anchors.margins: 16
                    anchors.topMargin: 40
                    focus: true
                    Keys.onEscapePressed: root.open = false

                    GridLayout {
                        id: controlsContent
                        width: parent.width
                        columns: 3
                        columnSpacing: 12
                        rowSpacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.columnSpan: 3
                            spacing: 10

                            Text {
                                text: userInfo.username
                                font.family: "sans-serif"
                                font.pixelSize: 18
                                font.bold: true
                                color: root.colText
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                id: clockText
                                font.family: "sans-serif"
                                font.pixelSize: 18
                                font.bold: false
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
                            Layout.columnSpan: 3
                            Layout.preferredHeight: 40
                            color: root.colors.cElevated
                            radius: 12
                            visible: root.aiActive
                            border.width: 0

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
                            Layout.minimumWidth: 0
                            Layout.preferredWidth: 1
                            spacing: 10

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                color: root.dndActive ? root.colSelection
                                    : silenceMouse.containsMouse
                                        ? root.colSelection : root.colors.cElevated
                                radius: 8

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        text: "\uF1F8"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 16
                                        color: root.dndActive ? root.colAccent : root.colText
                                    }
                                    Text {
                                        text: root.dndActive ? "DND Actif" : "Silence"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.colText
                                    }
                                }

                                MouseArea {
                                    id: silenceMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: root.notifications !== null
                                    onClicked: {
                                        root.notifications.dnd = !root.notifications.dnd
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                color: focusMouse.containsMouse
                                    ? root.colSelection : root.colors.cElevated
                                radius: 8

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

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
                                    id: focusMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
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
                            Layout.minimumWidth: 0
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 60
                            color: root.colors.cElevated
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
                                        text: root.pomoRunning ? "En cours · double-clic : reset" : "En pause"
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
                            Layout.minimumWidth: 0
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 56
                            color: root.colors.cElevated
                            radius: 12

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: "\uF1EB"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    color: root.colMuted
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true

                                    Text {
                                        text: "RÉSEAU WI-FI"
                                        font.pixelSize: 11
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
                            Layout.minimumWidth: 0
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 72
                            color: root.colors.cElevated
                            radius: 12

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: root.muted ? "\uF6A9" : "\uF028"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    color: root.muted ? root.colDanger : root.colMuted
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

                                    Slider {
                                        id: volumeSlider
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 100
                                        stepSize: 1
                                        implicitHeight: 28
                                        value: root.volume
                                        enabled: root.sink?.audio != null
                                        background: Rectangle {
                                            x: volumeSlider.leftPadding
                                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - 4
                                            width: volumeSlider.availableWidth
                                            height: 8
                                            radius: 4
                                            color: root.colSelection

                                            Rectangle {
                                                width: volumeSlider.visualPosition * parent.width
                                                height: parent.height
                                                radius: 4
                                                color: root.colAccent
                                            }
                                        }
                                        handle: Rectangle {
                                            x: volumeSlider.leftPadding
                                                + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - 7
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: root.colText
                                            border.width: 2
                                            border.color: root.colAccent
                                        }
                                        onMoved: {
                                            if (root.sink?.audio)
                                                root.sink.audio.volume = value / 100
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 72
                            color: root.colors.cElevated
                            radius: 12

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: "\uF185"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    color: root.colMuted
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

                                    Slider {
                                        id: brightnessSlider
                                        Layout.fillWidth: true
                                        from: 1
                                        to: 100
                                        stepSize: 1
                                        implicitHeight: 28
                                        value: root.brightness
                                        background: Rectangle {
                                            x: brightnessSlider.leftPadding
                                            y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - 4
                                            width: brightnessSlider.availableWidth
                                            height: 8
                                            radius: 4
                                            color: root.colSelection

                                            Rectangle {
                                                width: brightnessSlider.visualPosition * parent.width
                                                height: parent.height
                                                radius: 4
                                                color: root.colAccent
                                            }
                                        }
                                        handle: Rectangle {
                                            x: brightnessSlider.leftPadding
                                                + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                                            y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - 7
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: root.colText
                                            border.width: 2
                                            border.color: root.colAccent
                                        }
                                        onMoved: {
                                            root.brightness = Math.round(value)
                                            brightnessWriter.restart()
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 88
                            visible: root.player !== null
                            color: root.colors.cElevated
                            radius: 12

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 6

                                Text {
                                    Layout.fillWidth: true
                                    text: root.player?.trackTitle || "Lecture multimédia"
                                    color: root.colText
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.player?.trackArtist || ""
                                    color: root.colMuted
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 24

                                    Repeater {
                                        model: ["\uf048", root.player?.isPlaying
                                            ? "\uf04c" : "\uf04b", "\uf051"]

                                        delegate: Text {
                                            required property string modelData
                                            required property int index
                                            text: modelData
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 16
                                            color: index === 1 ? root.colAccent : root.colText
                                            opacity: enabled ? 1 : 0.35
                                            enabled: index === 0 ? !!root.player?.canGoPrevious
                                                : index === 2 ? !!root.player?.canGoNext
                                                : !!root.player?.canTogglePlaying

                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -5
                                                onClicked: {
                                                    if (index === 0) root.player?.previous()
                                                    else if (index === 1) root.player?.togglePlaying()
                                                    else root.player?.next()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.columnSpan: 3
                            spacing: 10

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                color: root.colors.cElevated
                                radius: 8
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
                                color: root.colors.cElevated
                                radius: 8
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
                                color: root.colors.cElevated
                                radius: 8
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
                                color: Qt.alpha(root.colDanger, 0.12)
                                radius: 8
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uF011"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: root.colDanger
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
}

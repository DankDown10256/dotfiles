import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool open: false
    property bool alive: false
    property var targetScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]

    function showOn(screen) { targetScreen = screen; open = true }
    function toggleOn(screen) { targetScreen = screen; open = !open }

    
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
    property int barInset: 30

    property var notifications: null
    readonly property bool dndActive: notifications?.dnd ?? false

    property bool aiActive: false
    property string aiToolName: ""
    property int aiCount: 0
    readonly property var aiTools: ({ claude: "Claude", opencode: "OpenCode", codex: "Codex" })

    property int brightness: 0
    property bool brightnessAvailable: false
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) || null
    readonly property var wifiNetworks: wifiDevice?.networks?.values || []
    property int timerDuration: 25


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
        function toggle(): void {
            root.toggleOn(Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0])
        }
    }

    QtObject { id: wifiInfo; readonly property string ssid: root.wifiNetworks.find(n => n.connected)?.name || "Non connecté" }
    QtObject { id: userInfo; readonly property string username: "Contrôles" }

    Process {
        id: briProc
        command: ["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",")
                root.brightnessAvailable = p.length >= 4
                if (root.brightnessAvailable) root.brightness = parseInt(p[3]) || 0
            }
        }
    }

    Timer {
        interval: 3000
        running: root.alive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            briProc.running = true
        }
    }

    Timer {
        id: pomoTimer
        interval: 1000
        repeat: true
        running: root.pomoRunning
        onTriggered: {
            if (root.pomoMinutes === 0 && root.pomoSeconds === 1) {
                root.pomoRunning = false
                root.pomoMinutes = root.timerDuration
                root.pomoSeconds = 0
                Quickshell.execDetached(["notify-send", "Minuteur terminé", "La durée est écoulée."])
            } else if (root.pomoSeconds > 0) {
                root.pomoSeconds--
            } else if (root.pomoMinutes > 0) {
                root.pomoMinutes--
                root.pomoSeconds = 59
            } else {
                root.pomoRunning = false
                root.pomoMinutes = root.timerDuration
                root.pomoSeconds = 0
                Quickshell.execDetached(["notify-send", "Minuteur terminé", "La durée est écoulée."])
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
            screen: root.targetScreen
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
                width: Math.min(420, parent.width - 24)
                height: Math.min(
                    controlsContent.implicitHeight + 24,
                    parent.height - root.barInset - 16
                )
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: root.barInset + 8
                anchors.rightMargin: 8

                color: root.colSurface
                radius: 0
                border.width: 1
                border.color: root.colors.cBorder

                transform: Translate {
                    y: card.shown ? 0 : -4

                    Behavior on y {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
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
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea { anchors.fill: parent }

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 12
                    contentWidth: width
                    contentHeight: controlsContent.implicitHeight
                    clip: true
                    focus: true
                    Keys.onEscapePressed: root.open = false

                    GridLayout {
                        id: controlsContent
                        width: parent.width
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            spacing: 10

                            Text {
                                text: userInfo.username
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 14
                                font.bold: true
                                color: root.colText
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                id: clockText
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 14
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

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredWidth: 1
                            spacing: 10

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                color: root.dndActive ? root.colSelection
                                    : silenceMouse.containsMouse
                                        ? root.colSelection : root.colors.cElevated
                                radius: 0

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        text: "\uF1F8"
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 14
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
                                Layout.preferredHeight: 36
                                color: focusMouse.containsMouse
                                    ? root.colSelection : root.colors.cElevated
                                radius: 0

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        text: "\uF2F2"
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 14
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
                                        root.pomoMinutes = root.timerDuration
                                        root.pomoSeconds = 0
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            Text { text: "Minuteur (min)"; color: root.colText; font.family: "Iosevka Nerd Font" }
                            SpinBox {
                                id: durationInput
                                from: 1; to: 999; value: root.timerDuration
                                implicitWidth: 92; implicitHeight: 32
                                enabled: !root.pomoRunning
                                onValueModified: { root.timerDuration = value; root.pomoMinutes = value; root.pomoSeconds = 0 }
                                contentItem: TextInput {
                                    text: durationInput.textFromValue(durationInput.value, durationInput.locale)
                                    color: durationInput.enabled ? root.colText : root.colMuted
                                    font.family: "Iosevka Nerd Font"; font.pixelSize: 12
                                    horizontalAlignment: Qt.AlignHCenter; verticalAlignment: Qt.AlignVCenter
                                    readOnly: true
                                }
                                background: Rectangle { color: root.colors.cElevated; border.color: root.colors.cBorder }
                                up.indicator: Rectangle {
                                    x: durationInput.width - width; width: 25; height: durationInput.height
                                    color: durationInput.up.pressed ? root.colSelection : root.colors.cSurface
                                    Text { anchors.centerIn: parent; text: "+"; color: root.colText; font.family: "Iosevka Nerd Font" }
                                }
                                down.indicator: Rectangle {
                                    x: 0; width: 25; height: durationInput.height
                                    color: durationInput.down.pressed ? root.colSelection : root.colors.cSurface
                                    Text { anchors.centerIn: parent; text: "−"; color: root.colText; font.family: "Iosevka Nerd Font" }
                                }
                            }
                            Button { text: root.pomoRunning ? "Pause" : "Démarrer"; onClicked: root.pomoRunning = !root.pomoRunning
                                implicitHeight: 32; leftPadding: 10; rightPadding: 10
                                contentItem: Text { text: parent.text; color: root.colText; font.family: "Iosevka Nerd Font"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { color: parent.down || parent.hovered ? root.colSelection : root.colors.cElevated; border.color: root.colors.cBorder }
                            }
                            Button { text: "Reset"; onClicked: { root.pomoRunning = false; root.pomoMinutes = root.timerDuration; root.pomoSeconds = 0 }
                                implicitHeight: 32; leftPadding: 10; rightPadding: 10
                                contentItem: Text { text: parent.text; color: root.colText; font.family: "Iosevka Nerd Font"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { color: parent.down || parent.hovered ? root.colSelection : root.colors.cElevated; border.color: root.colors.cBorder }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredWidth: 1
                            Layout.columnSpan: 2
                            Layout.preferredHeight: 56
                            color: root.colors.cElevated
                            radius: 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "\uF1EB"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 14
                                    color: root.wifiEnabled ? root.colAccent : root.colMuted
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true

                                    Text {
                                        text: root.wifiEnabled ? "WI-FI · ACTIVÉ" : "WI-FI · DÉSACTIVÉ"
                                        font.pixelSize: 11
                                        color: root.colMuted
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: root.wifiEnabled ? wifiInfo.ssid : "Réseau désactivé"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.colText
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 62
                                    implicitHeight: 28
                                    radius: 0
                                    color: wifiToggleMouse.containsMouse ? root.colSelection : root.colSurface
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.wifiEnabled ? "Couper" : "Activer"
                                        color: root.colText
                                        font.pixelSize: 11
                                    }
                                    MouseArea {
                                        id: wifiToggleMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
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
                            radius: 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: root.muted ? "\uF6A9" : "\uF028"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 14
                                    color: root.muted ? root.colDanger : root.colMuted
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Volume"; font.pixelSize: 11; color: root.colText }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.volume + "%"; font.pixelSize: 11; color: root.colMuted }
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
                                            radius: 0
                                            color: root.colSelection

                                            Rectangle {
                                                width: volumeSlider.visualPosition * parent.width
                                                height: parent.height
                                                radius: 0
                                                color: root.colAccent
                                            }
                                        }
                                        handle: Rectangle {
                                            x: volumeSlider.leftPadding
                                                + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - 7
                                            width: 14
                                            height: 14
                                            radius: 0
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
                            radius: 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "\uF185"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 14
                                    color: root.colMuted
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Luminosité"; font.pixelSize: 11; color: root.colText }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.brightness + "%"; font.pixelSize: 11; color: root.colMuted }
                                    }

                                    Slider {
                                        id: brightnessSlider
                                        Layout.fillWidth: true
                                        from: 1
                                        to: 100
                                        stepSize: 1
                                        implicitHeight: 28
                                        value: root.brightness
                                        enabled: root.brightnessAvailable
                                        background: Rectangle {
                                            x: brightnessSlider.leftPadding
                                            y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - 4
                                            width: brightnessSlider.availableWidth
                                            height: 8
                                            radius: 0
                                            color: root.colSelection

                                            Rectangle {
                                                width: brightnessSlider.visualPosition * parent.width
                                                height: parent.height
                                                radius: 0
                                                color: root.colAccent
                                            }
                                        }
                                        handle: Rectangle {
                                            x: brightnessSlider.leftPadding
                                                + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                                            y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - 7
                                            width: 14
                                            height: 14
                                            radius: 0
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
                            radius: 0

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
                                        model: ["Préc.", root.player?.isPlaying
                                            ? "Pause" : "Lecture", "Suiv."]

                                        delegate: Text {
                                            required property string modelData
                                            required property int index
                                            text: modelData
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 14
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

                    }
                }
            }
        }
    }
}

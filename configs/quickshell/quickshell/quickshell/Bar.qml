import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property bool barVisible: true
    required property var colors
    required property var panels
    required property var notifications
    required property var capture
    required property var controlCenter
    property bool caffeine: false
    property int updateCount: 0
    property string keyboardLayout: ""
    property bool ethernetUp: false
    readonly property var microphone: Pipewire.defaultAudioSource
    property bool microphoneReady: false
    PwObjectTracker { objects: [root.microphone] }
    Connections {
        target: root.microphone?.audio || null
        function onMutedChanged() {
            if (root.microphoneReady)
                root.showOsd("microphone", Math.round((root.microphone?.audio?.volume || 0) * 100), root.microphone?.audio?.muted || false)
            root.microphoneReady = true
        }
        function onVolumesChanged() {
            if (root.microphoneReady)
                root.showOsd("microphone", Math.round((root.microphone?.audio?.volume || 0) * 100), root.microphone?.audio?.muted || false)
            root.microphoneReady = true
        }
    }

    IpcHandler {
        target: "bar"
        function toggle() {
            root.barVisible = !root.barVisible
        }
        function show() {
            root.barVisible = true
        }
        function hide() {
            root.barVisible = false
        }
        function caffeine(): void { root.caffeine = !root.caffeine }
    }
    
    readonly property color bg: colors.cBg
    readonly property color fg: colors.cText
    readonly property color dim: colors.cMuted
    readonly property color accent: colors.cAccent
    readonly property color warn: colors.cWarning
    readonly property string font: "JetBrainsMono Nerd Font"

    property int volume: 0
    property bool muted: false

    property bool audioReady: false
    property bool brightnessReady: false
    property bool audioRequested: false
    property bool brightnessRequested: false
    property bool osdOpen: false
    property string osdKind: "volume"
    property int osdValue: 0
    property bool osdMuted: false
    property string osdLabel: ""

    function showOsd(kind, value, isMuted) {
        osdKind = kind
        osdValue = value
        osdMuted = isMuted
        osdOpen = true
        osdTimeout.restart()
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            if (Hyprland.focusedWorkspace) {
                root.osdLabel = "Espace " + Hyprland.focusedWorkspace.id
                root.showOsd("workspace", 100, false)
            }
        }
    }

    IpcHandler {
        target: "osd"

        function volume(): void {
            root.audioRequested = true
            if (!audioReader.running) audioReader.running = true
        }

        function brightness(): void {
            root.brightnessRequested = true
            if (!briProc.running) briProc.running = true
        }
        function microphone(): void {
            root.showOsd("microphone", Math.round((root.microphone?.audio?.volume || 0) * 100), root.microphone?.audio?.muted || false)
        }
    }

    Timer {
        id: osdTimeout
        interval: 1400
        onTriggered: root.osdOpen = false
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
        anchors { top: true; left: true }
        margins { top: (root.barVisible ? 30 : 0) + 8; left: 12 }
        implicitWidth: 280
        implicitHeight: 56
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"
        visible: root.osdOpen || osdCard.opacity > 0
        mask: Region {}

        Rectangle {
            id: osdCard
            anchors.fill: parent
            radius: 6
            color: root.colors.cSurface
            border.width: 1
            border.color: root.colors.cBorder
            opacity: root.osdOpen ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Text {
                    text: root.osdKind === "workspace" ? "\uf00a"
                        : root.osdKind === "microphone" ? "\uf130"
                        : root.osdKind === "brightness" ? "\uf185"
                        : root.osdMuted ? "\uf6a9" : "\uf028"
                    font.family: root.font
                    font.pixelSize: 14
                    color: root.osdMuted ? root.dim : root.accent
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0

                        Text {
                            text: root.osdKind === "workspace" ? root.osdLabel
                                : root.osdKind === "microphone" ? (root.osdMuted ? "Micro coupé" : "Microphone")
                                : root.osdKind === "brightness" ? "Luminosité"
                                : root.osdMuted ? "Son coupé" : "Volume"
                            font.family: "sans-serif"
                            font.pixelSize: 13
                            color: root.fg
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.osdValue + "%"
                            visible: root.osdKind !== "workspace"
                            font.family: "sans-serif"
                            font.pixelSize: 11
                            color: root.dim
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        visible: root.osdKind !== "workspace"
                        radius: 2
                        color: root.colors.cSelection

                        Rectangle {
                            width: parent.width * Math.min(1, Math.max(
                                0, root.osdMuted ? 0 : root.osdValue / 100
                            ))
                            height: parent.height
                            radius: 2
                            color: root.accent

                            Behavior on width {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: audioReader
        command: ["env", "LC_ALL=C", "sh", "-c",
            "pactl get-sink-volume @DEFAULT_SINK@; pactl get-sink-mute @DEFAULT_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const vol = text.match(/(\d+)%/)
                const mute = text.match(/Mute:\s*(yes|no)/)
                if (!vol || !mute) {
                    root.audioRequested = false
                    return
                }
                const nextVolume = parseInt(vol[1])
                const nextMuted = mute[1] === "yes"
                const changed = nextVolume !== root.volume || nextMuted !== root.muted
                root.volume = nextVolume
                root.muted = nextMuted
                if ((root.audioReady && changed) || root.audioRequested)
                    root.showOsd("volume", nextVolume, nextMuted)
                root.audioReady = true
                root.audioRequested = false
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

    Process {
        id: ethernetProc
        command: ["env", "LC_ALL=C", "nmcli", "-t", "-f", "TYPE,STATE", "device"]
        stdout: StdioCollector { onStreamFinished: root.ethernetUp = text.split("\n").some(line => line.startsWith("ethernet:connected")) }
    }
    Process {
        id: keyboardProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const devices = JSON.parse(text)
                    const keyboard = devices.keyboards.find(item => item.main) || devices.keyboards[0]
                    root.keyboardLayout = keyboard?.active_keymap || ""
                } catch (error) { root.keyboardLayout = "" }
            }
        }
    }
    Process {
        id: updatesProc
        command: ["pacman", "-Qu"]
        stdout: StdioCollector { onStreamFinished: root.updateCount = text.split("\n").filter(Boolean).length }
    }
    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { ethernetProc.running = true; keyboardProc.running = true }
    }
    Timer { interval: 3600000; running: true; repeat: true; triggeredOnStart: true; onTriggered: updatesProc.running = true }

    property int brightness: 0
    Process {
        id: briProc
        command: ["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",");
                const nextBrightness = p.length >= 4 ? parseInt(p[3]) : NaN
                if (isNaN(nextBrightness)) {
                    root.brightnessRequested = false
                    return
                }
                const changed = nextBrightness !== root.brightness
                root.brightness = nextBrightness
                if ((root.brightnessReady && changed) || root.brightnessRequested)
                    root.showOsd("brightness", nextBrightness, false)
                root.brightnessReady = true
                root.brightnessRequested = false
            }
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: briProc.running = true
    }

    property bool batPresent: false
    property int batPercent: 0
    property bool batCharging: false
    Process {
        id: batProc
        command: ["sh", "-c",
            "cat /sys/class/power_supply/BAT0/capacity /sys/class/power_supply/BAT0/status 2>/dev/null"]
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
        const charge = panels.battery?.isPresent ? Math.round(panels.battery.percentage * 100)
            : panels.batteryPresent ? panels.batteryPercent : batPercent
        if (batCharging || panels.batteryCharging) return "\uf0e7";
        if (charge > 85) return "\uf240";
        if (charge > 60) return "\uf241";
        if (charge > 35) return "\uf242";
        if (charge > 10) return "\uf243";
        return "\uf244";
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property var player: {
        const l = Mpris.players.values;
        return l.find(p => p.isPlaying) ?? l[0] ?? null;
    }

    component Ico: Text {
        color: root.fg
        font.pixelSize: 13
        font.family: root.font
        verticalAlignment: Text.AlignVCenter
        Layout.alignment: Qt.AlignCenter
    }


    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            readonly property bool fullscreenWindow: Hyprland.monitors.values.some(m =>
                m.name === screen.name && m.hasFullscreen)
            visible: root.barVisible && !fullscreenWindow

            anchors { top: true; left: true; right: true }
            implicitHeight: 30
            exclusiveZone: visible ? implicitHeight : 0
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: root.bg
                border.width: 1
                border.color: root.colors.cBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    Rectangle {
                        implicitWidth: 26; implicitHeight: 24; radius: 4
                        color: launchMouse.containsMouse ? root.colors.cSelection : "transparent"
                        Text { anchors.centerIn: parent; text: "\uf0c9"; color: root.accent; font.family: root.font; font.pixelSize: 13 }
                        MouseArea { id: launchMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"]) }
                    }

                    Repeater {
                        model: 10
                        delegate: Rectangle {
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property bool focused: Hyprland.monitors.values.some(m => m.name === bar.screen.name && m.activeWorkspace?.id === wsId)
                            readonly property bool occupied: Hyprland.toplevels.values.some(w => w.workspace?.id === wsId)
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 4
                            color: focused ? root.colors.cSelection : wsMouse.containsMouse ? root.colors.cElevated : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: wsId
                                color: focused ? root.accent : occupied ? root.fg : root.dim
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: focused
                            }
                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton)
                                        Quickshell.execDetached(["qs", "ipc", "call", "workspaceoverview", "toggle"])
                                    else
                                        Hyprland.dispatch("workspace " + wsId)
                                }
                            }
                        }
                    }

                    Rectangle { Layout.alignment: Qt.AlignVCenter; implicitWidth: 1; implicitHeight: 14; color: root.colors.cBorder }

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.maximumWidth: Math.max(0, Math.min(230, bar.width / 2 - 420))
                        text: Hyprland.activeToplevel?.monitor?.name === bar.screen.name
                            ? Hyprland.activeToplevel.title : "Desktop"
                        color: root.fg
                        font.family: "sans-serif"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 7
                        Text {
                            visible: root.notifications.dnd
                            text: ""; color: root.warn; font.family: root.font; font.pixelSize: 12
                            MouseArea { anchors.fill: parent; onClicked: root.notifications.dnd = false }
                        }
                        Text {
                            visible: root.panels.nightLight
                            text: ""; color: root.warn; font.family: root.font; font.pixelSize: 12
                            MouseArea { anchors.fill: parent; onClicked: root.panels.showPanel("brightness", bar.screen, mapToItem(null, width, 0).x) }
                        }
                        Text {
                            visible: root.capture.recording
                            text: "● REC"; color: root.colors.cDanger; font.family: root.font; font.pixelSize: 11
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["qs", "ipc", "call", "capture", "toggle"]) }
                        }
                        Text {
                            visible: root.caffeine
                            text: ""; color: root.accent; font.family: root.font; font.pixelSize: 12
                            MouseArea { anchors.fill: parent; onClicked: root.caffeine = false }
                        }
                    }

                    RowLayout {
                        spacing: 6
                        Repeater {
                            model: SystemTray.items
                            delegate: MouseArea {
                                id: trayItem
                                required property var modelData
                                implicitWidth: 20
                                implicitHeight: 20
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) modelData.activate()
                                    else if (modelData.hasMenu) {
                                        const p = mapToItem(null, mouse.x, mouse.y)
                                        modelData.display(bar, p.x, p.y)
                                    }
                                }
                                IconImage { anchors.fill: parent; source: trayItem.modelData.icon }
                            }
                        }
                    }

                    Rectangle { Layout.alignment: Qt.AlignVCenter; implicitWidth: 1; implicitHeight: 14; color: root.colors.cBorder }

                    Text {
                        text: root.ethernetUp ? "\uf6ff" : "\uf1eb"
                        font.family: root.font
                        font.pixelSize: 13
                        color: root.ethernetUp || root.wifiUp ? root.fg : root.dim
                        MouseArea { anchors.fill: parent; onClicked: root.panels.showPanel("network", bar.screen, mapToItem(null, width, 0).x) }
                    }

                    Text {
                        text: root.muted ? "\uf6a9" : "\uf028"
                        font.family: root.font
                        font.pixelSize: 13
                        color: root.muted ? root.warn : root.fg
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.panels.showPanel("audio", bar.screen, mapToItem(null, width, 0).x)
                            onWheel: wheel => {
                                Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", wheel.angleDelta.y > 0 ? "+5%" : "-5%"])
                                audioDebounce.restart()
                            }
                        }
                    }

                    Text {
                        visible: !!root.microphone?.audio && root.microphone.audio.muted
                        text: !root.microphone?.audio || root.microphone.audio.muted ? "\uf131" : "\uf130"
                        font.family: root.font; font.pixelSize: 13
                        color: !root.microphone?.audio ? root.dim : root.microphone.audio.muted ? root.warn : root.fg
                        MouseArea { anchors.fill: parent; onClicked: root.panels.showPanel("audio", bar.screen, mapToItem(null, width, 0).x) }
                    }

                    RowLayout {
                        visible: root.batPresent || root.panels.battery?.isPresent || root.panels.batteryPresent
                        spacing: 4
                        Ico { text: root.batIcon(); color: (root.panels.batteryPresent ? root.panels.batteryPercent : root.batPercent) <= 15 && !root.batCharging ? root.warn : root.batCharging ? root.accent : root.fg }
                        Text { text: (root.panels.battery?.isPresent ? Math.round(root.panels.battery.percentage * 100) : root.panels.batteryPresent ? root.panels.batteryPercent : root.batPercent) + "%"; color: root.fg; font.family: root.font; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; onClicked: root.panels.showPanel("battery", bar.screen, mapToItem(null, width, 0).x) }
                    }

                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 24
                        radius: 4
                        color: controlMouse.containsMouse ? root.colors.cSelection : "transparent"
                        Text { anchors.centerIn: parent; text: "\uf1de"; color: root.dim; font.family: root.font; font.pixelSize: 12 }
                        MouseArea { id: controlMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.controlCenter.toggleOn(bar.screen) }
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: centeredClock.implicitWidth + 12
                    height: 24
                    radius: 4
                    color: root.bg
                    z: 1

                    Text {
                        id: centeredClock
                        anchors.centerIn: parent
                        text: bar.width < 1100
                            ? Qt.formatTime(clock.date, "HH:mm")
                            : Qt.formatDateTime(clock.date, "ddd d · HH:mm")
                        color: root.fg
                        font.family: root.font
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.panels.showPanel("calendar", bar.screen, bar.width / 2)
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: caffeineSurface
            required property var modelData
            screen: modelData
            visible: root.caffeine
            anchors.bottom: true
            implicitWidth: 1
            implicitHeight: 1
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            IdleInhibitor { window: caffeineSurface; enabled: root.caffeine }
        }
    }
}

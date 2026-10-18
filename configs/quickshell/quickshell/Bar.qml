import Quickshell
import Quickshell.Wayland
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

    property bool barVisible: true
    required property var colors

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

    function showOsd(kind, value, isMuted) {
        osdKind = kind
        osdValue = value
        osdMuted = isMuted
        osdOpen = true
        osdTimeout.restart()
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
    }

    Timer {
        id: osdTimeout
        interval: 1400
        onTriggered: root.osdOpen = false
    }

    PanelWindow {
        anchors.left: true
        margins.bottom: (root.barVisible ? 32 : 0) + 12
        implicitWidth: 280
        implicitHeight: 64
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
            radius: 16
            color: root.colors.cBg
            border.width: 1
            border.color: Qt.alpha(root.colors.cBorder, 0.65)
            opacity: root.osdOpen ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.osdOpen ? 200 : 140
                    easing.type: Easing.OutCubic
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: root.osdKind === "brightness" ? "\uf185"
                        : root.osdMuted ? "\uf6a9" : "\uf028"
                    font.family: root.font
                    font.pixelSize: 16
                    color: root.osdMuted ? root.dim : root.accent
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.osdKind === "brightness" ? "Luminosité"
                                : root.osdMuted ? "Son coupé" : "Volume"
                            font.family: "sans-serif"
                            font.pixelSize: 13
                            color: root.fg
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.osdValue + "%"
                            font.family: "sans-serif"
                            font.pixelSize: 11
                            color: root.dim
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4
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

    property int brightness: 0
    Process {
        id: briProc
        command: ["brightnessctl", "-m"]
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
            visible: root.barVisible

            anchors { top: true; bottom: true; left: true }
            implicitWidth: 40
            exclusiveZone: root.barVisible ? implicitWidth : 0
            color: root.bg

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 16
                anchors.bottomMargin: 16
                spacing: 16

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: workspaceRow.implicitWidth + 8
                    implicitHeight: workspaceRow.implicitHeight + 8
                    radius: 8
                    color: "transparent"

                    ColumnLayout {
                        id: workspaceRow
                        anchors.centerIn: parent
                        spacing: 8

                        Repeater {
                            model: 5
                            Rectangle {
                                id: ws
                                required property int index
                                readonly property int wsId: index + 1
                                readonly property bool focused: Hyprland.focusedWorkspace?.id === wsId
                                readonly property bool exists: Hyprland.workspaces.values.some(w => w.id === wsId)

                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 24
                                implicitHeight: 24
                                radius: 8
                                color: workspaceMouse.containsMouse
                                    ? root.colors.cSurface
                                    : "transparent"

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 4
                                    height: ws.focused ? 16 : 4
                                    radius: 2
                                    color: ws.focused ? root.accent
                                        : ws.exists ? root.dim : root.colors.cSelection

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on color {
                                        ColorAnimation { duration: 120 }
                                    }
                                }
                                MouseArea {
                                    id: workspaceMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: Hyprland.dispatch("workspace " + ws.wsId)
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.height, 280)
                        rotation: -90
                        visible: text.length > 0
                        text: Hyprland.focusedWindow ? Hyprland.focusedWindow.title : ""
                        font.pixelSize: 11
                        font.bold: false
                        font.family: "sans-serif"
                        color: root.dim
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: statusRow.implicitWidth + 8
                    implicitHeight: statusRow.implicitHeight + 8
                    radius: 8
                    color: "transparent"

                    ColumnLayout {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: 14

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

                        Ico {
                            text: "\uf1eb"
                            color: !root.wifiUp ? root.dim : (root.wifiSignal < 30 ? root.warn : root.fg)
                        }

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: Math.max(24, soundRow.implicitWidth)
                            implicitHeight: 24

                            RowLayout {
                                id: soundRow
                                anchors.centerIn: parent
                                spacing: 4
                                Ico {
                                    text: root.muted ? "\uf6a9" : "\uf028"
                                    color: root.muted ? root.warn : root.fg
                                }
                                Text {
                                    text: root.volume
                                    visible: false
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

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: briRow.implicitWidth
                            implicitHeight: briRow.implicitHeight
                            visible: false

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

                        ColumnLayout {
                            visible: root.batPresent
                            spacing: 4
                            Layout.alignment: Qt.AlignHCenter

                            readonly property bool low: root.batPercent <= 15 && !root.batCharging

                            Ico {
                                text: root.batIcon()
                                color: parent.low ? root.warn : (root.batCharging ? root.accent : root.fg)
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.batPercent + "%"
                                color: parent.low ? root.warn : root.fg
                                font.family: root.font
                                font.pixelSize: 10
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            color: root.fg
                            font.pixelSize: 11
                            font.family: root.font
                            font.bold: false
                            text: Qt.formatDateTime(clock.date, "HH\nmm")
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: 8
                            color: controlMouse.containsMouse ? root.colors.cSelection
                                : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "\uf1de"
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.dim
                            }

                            MouseArea {
                                id: controlMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Quickshell.execDetached([
                                    "qs", "ipc", "call", "controlcenter", "toggle"
                                ])
                            }
                        }
                    }
                }
            }
        }
    }
}

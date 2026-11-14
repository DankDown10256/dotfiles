import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Networking
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
    readonly property bool ethernetUp: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property bool wifiUp: Networking.devices.values.some(d => d.type === DeviceType.Wifi && d.connected)
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }
    Connections {
        target: root.sink?.audio || null
        function onMutedChanged() { root.audioChanged() }
        function onVolumesChanged() { root.audioChanged() }
    }
    function audioChanged() {
        if (audioReady) showOsd("volume", volume, muted)
        audioReady = true
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
    readonly property string font: "Iosevka Nerd Font"

    readonly property int volume: Math.round((sink?.audio?.volume || 0) * 100)
    readonly property bool muted: sink?.audio?.muted || false

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

    IpcHandler {
        target: "osd"

        function volume(): void {
            root.showOsd("volume", root.volume, root.muted)
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
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
        anchors { top: true; left: true }
        margins { top: (root.barVisible ? 30 : 0) + 8; left: 12 }
        implicitWidth: 280
        implicitHeight: 46
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

    property string ipv6Status: "Useless Protocol: Down"
    property string cpuStatus: "CPU: -- °C"
    property string diskStatus: "Disk: --"
    property string wifiStatus: "W: down"
    property string ethernetStatus: "E: down"
    property string memoryStatus: "RAM: -- / --"
    property string dateStatus: ""

    Process {
        id: statusProc
        command: ["sh", "-c", `
            ipv6=$(ip -6 -o addr show scope global 2>/dev/null |
                awk 'NR == 1 { split($4, a, "/"); print a[1] }')
            printf '%s\\n' "\${ipv6:-Down}"

            cpu=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
            if [ -n "$cpu" ]; then
                awk -v temp="$cpu" 'BEGIN { printf "%.0f\\n", temp / 1000 }'
            else
                printf '%s\\n' "--"
            fi

            df -h / 2>/dev/null | awk 'NR == 2 { print $4 }'

            wifi=$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null |
                awk -F: '$2 == "wifi" { print $1; exit }')
            wifi_ip=$(ip -4 -o addr show dev "$wifi" 2>/dev/null |
                awk 'NR == 1 { split($4, a, "/"); print a[1] }')
            if [ -n "$wifi_ip" ]; then
                quality=$(nmcli -t -f IN-USE,SIGNAL device wifi list ifname "$wifi" 2>/dev/null |
                    awk -F: '$1 == "*" { print $2; exit }')
                printf 'W: (%s%%) IP: %s\\n' "\${quality:---}" "$wifi_ip"
            else
                printf '%s\\n' "W: down"
            fi

            ethernet=$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null |
                awk -F: '$2 == "ethernet" { print $1; exit }')
            ethernet_ip=$(ip -4 -o addr show dev "$ethernet" 2>/dev/null |
                awk 'NR == 1 { split($4, a, "/"); print a[1] }')
            if [ -n "$ethernet_ip" ]; then
                speed=$(cat "/sys/class/net/$ethernet/speed" 2>/dev/null)
                printf 'E: %s (%s Mbit/s)\\n' "$ethernet_ip" "\${speed:---}"
            else
                printf '%s\\n' "E: down"
            fi

            awk '
                /^MemTotal:/ { total = $2 }
                /^MemFree:/ { free = $2 }
                /^Buffers:/ { buffers = $2 }
                /^Cached:/ { cached = $2 }
                END {
                    printf "%.1f GiB / %.1f GiB\\n",
                        (total - free - buffers - cached) / 1048576,
                        total / 1048576
                }
            ' /proc/meminfo
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length < 6) return
                root.ipv6Status = "Useless Protocol: " + lines[0]
                root.cpuStatus = "CPU: " + lines[1] + " °C"
                root.diskStatus = "Disk: " + lines[2]
                root.wifiStatus = lines[3]
                root.ethernetStatus = lines[4]
                root.memoryStatus = "RAM: " + lines[5]
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.dateStatus = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm:ss")
            if (!statusProc.running) statusProc.running = true
        }
    }

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
            anchors { bottom: true; left: true; right: true }
            implicitHeight: 20
            exclusiveZone: root.barVisible ? implicitHeight : 0
            color: "#000000"

            readonly property var monitor: Hyprland.monitors.values.find(m => m.name === screen.name)
            readonly property var workspaces: Hyprland.workspaces.values
                .filter(w => w.monitor?.name === screen.name && (w.id === bar.monitor?.activeWorkspace?.id || Hyprland.toplevels.values.some(t => t.workspace?.id === w.id)))
                .sort((a, b) => a.id - b.id)

            RowLayout {
                anchors.fill: parent
                spacing: 0
                Repeater {
                    model: ScriptModel { values: bar.workspaces }
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillHeight: true
                        implicitWidth: 28
                        color: bar.monitor?.activeWorkspace?.id === modelData.id ? "#285577" : "#222222"
                        border.width: 1
                        border.color: bar.monitor?.activeWorkspace?.id === modelData.id ? "#4c7899" : "#333333"
                        Text { anchors.centerIn: parent; text: parent.modelData.name; color: "#ffffff"; font.family: root.font; font.pixelSize: 11 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Hyprland.dispatch("workspace " + parent.modelData.id)
                            onWheel: event => {
                                const i = bar.workspaces.findIndex(w => w.id === bar.monitor?.activeWorkspace?.id)
                                const next = Math.max(0, Math.min(bar.workspaces.length - 1, i + (event.angleDelta.y < 0 ? 1 : -1)))
                                if (bar.workspaces[next]) Hyprland.dispatch("workspace " + bar.workspaces[next].id)
                            }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                Repeater {
                    model: [
                        { text: root.ipv6Status, action: "" },
                        { text: root.cpuStatus, action: "" },
                        { text: root.diskStatus, action: "" },
                        { text: root.wifiStatus, action: "control" },
                        { text: root.ethernetStatus, action: "control" },
                        { text: root.muted ? "VOL: muted" : "VOL: " + root.volume + "%", action: "control" },
                        { text: root.memoryStatus, action: "" },
                        { text: "BAT: " + (root.panels.battery?.isPresent ? Math.round(root.panels.battery.percentage * 100) + "%" : "--"), action: "control" },
                        { text: root.dateStatus, action: "calendar" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillHeight: true
                        implicitWidth: statusText.implicitWidth + 16
                        color: "transparent"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 12
                            color: "#666666"
                            visible: parent.index > 0
                        }
                        Text {
                            id: statusText
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            color: parent.index === 7 && root.panels.battery?.percentage < 0.2 ? "#ff0000" : "#ffffff"
                            font.family: root.font
                            font.pixelSize: 10
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (parent.modelData.action === "control")
                                    root.controlCenter.toggleOn(bar.screen)
                                else if (parent.modelData.action === "calendar")
                                    root.panels.showPanel("calendar", bar.screen, mapToItem(null, width / 2, 0).x)
                            }
                        }
                    }
                }
                Repeater {
                    model: SystemTray.items
                    delegate: MouseArea {
                        required property var modelData
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 22; implicitHeight: 20
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) modelData.activate()
                            else if (modelData.hasMenu) {
                                const p = mapToItem(null, mouse.x, mouse.y)
                                modelData.display(bar, p.x, p.y)
                            }
                        }
                        IconImage { anchors.centerIn: parent; implicitSize: 16; source: parent.modelData.icon }
                    }
                }
            }
        }
    }
}

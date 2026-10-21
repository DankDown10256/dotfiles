import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
    id: root
    required property var colors
    property int barInset: 30
    property bool open: false
    property string page: "audio"
    property var targetScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
    property int popupRight: 10
    property bool wifiEnabled: false
    property string wifiDevice: ""
    property string ethernetDevice: ""
    property bool ethernetConnected: false
    property string activeSsid: ""
    property int signalStrength: 0
    property var networks: []
    property string pendingSsid: ""
    property bool bluetoothAvailable: false
    property bool bluetoothEnabled: false
    property var bluetoothDevices: []
    property bool brightnessAvailable: false
    property bool profileAvailable: false
    property int brightness: 0
    property bool batteryPresent: false
    property int batteryPercent: 0
    property bool batteryCharging: false
    property int batteryTime: 0
    property string weatherCity: Quickshell.env("QS_WEATHER_CITY") || "Paris"
    property var weather: null
    property string weatherError: ""
    property int monthOffset: 0
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var player: {
        const players = Mpris.players.values
        return players.find(p => p.isPlaying) ?? players[0] ?? null
    }
    readonly property var battery: UPower.displayDevice
    readonly property var audioNodes: Pipewire.nodes.values.filter(n => n.audio && n.ready)

    component PanelButton: Button {
        id: control
        implicitHeight: 30
        font.pixelSize: 12
        contentItem: Text {
            text: control.text
            color: control.enabled ? root.colors.cText : root.colors.cMuted
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 4
            color: control.hovered || control.activeFocus ? root.colors.cSelection : root.colors.cElevated
            border.width: 1
            border.color: root.colors.cBorder
            opacity: control.enabled ? 1 : 0.5
        }
    }

    component PanelSlider: Slider {
        id: control
        implicitHeight: 28
        background: Rectangle {
            x: control.leftPadding
            y: control.topPadding + control.availableHeight / 2 - 3
            width: control.availableWidth
            height: 6
            radius: 3
            color: root.colors.cSelection
            Rectangle {
                width: control.visualPosition * parent.width
                height: parent.height
                radius: 3
                color: root.colors.cAccent
            }
        }
        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + control.availableHeight / 2 - height / 2
            width: 14
            height: 14
            radius: 7
            color: root.colors.cText
            border.width: 1
            border.color: root.colors.cAccent
        }
    }

    PwObjectTracker { objects: root.audioNodes }

    FileView {
        id: settingsFile
        path: Quickshell.stateDir + "/workstation-settings.json"
        printErrors: false
        onLoaded: {
            if (!Quickshell.env("QS_WEATHER_CITY") && settingsStore.city) {
                root.weatherCity = settingsStore.city
                weatherRead.running = true
            }
        }
        JsonAdapter { id: settingsStore; property string city: "" }
    }

    function showPanel(name, target, anchorX) {
        if (open && page === name && (!target || targetScreen === target)) { open = false; return }
        page = name
        targetScreen = target || Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
        if (anchorX !== undefined) {
            const panelWidth = Math.min(name === "calendar" ? 390 : 430, targetScreen.width - 20)
            const desiredRight = name === "calendar"
                ? targetScreen.width - anchorX - panelWidth / 2
                : targetScreen.width - anchorX
            popupRight = Math.max(10, Math.min(targetScreen.width - panelWidth - 10, desiredRight))
        }
        open = true
        refresh()
    }
    function refresh() {
        if (page === "network") { wifiRadio.running = true; wifiList.running = true; wifiDeviceProc.running = true }
        if (page === "bluetooth") { bluetoothState.running = true; bluetoothList.running = true }
        if (page === "brightness") brightnessRead.running = true
        if (page === "weather") weatherRead.running = true
    }
    function parseNmcli(line) {
        return line.replace(/\\:/g, "\u0001").split(":").map(s => s.replace(/\u0001/g, ":"))
    }
    function duration(seconds) {
        if (!seconds || seconds <= 0) return "Estimation indisponible"
        return Math.floor(seconds / 3600) + " h " + Math.floor((seconds % 3600) / 60) + " min"
    }
    function clockTime(seconds) {
        const s = Math.max(0, Math.floor(seconds || 0))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }
    function run(command) { Quickshell.execDetached(command) }
    function connectWifi() {
        if (!pendingSsid || !wifiPassword.text) return
        run(["nmcli", "device", "wifi", "connect", pendingSsid, "password", wifiPassword.text])
        wifiPassword.clear()
        pendingSsid = ""
        refreshDelay.restart()
    }

    IpcHandler {
        target: "systempanels"
        function audio(): void { root.showPanel("audio") }
        function network(): void { root.showPanel("network") }
        function bluetooth(): void { root.showPanel("bluetooth") }
        function battery(): void { root.showPanel("battery") }
        function brightness(): void { root.showPanel("brightness") }
        function calendar(): void { root.showPanel("calendar") }
        function weather(): void { root.showPanel("weather") }
        function media(): void { root.showPanel("media") }
        function hide(): void { root.open = false }
    }

    Process {
        id: wifiRadio
        command: ["env", "LC_ALL=C", "nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector { onStreamFinished: root.wifiEnabled = text.trim() === "enabled" }
    }
    Process {
        id: wifiDeviceProc
        command: ["env", "LC_ALL=C", "nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                const row = text.split("\n").map(root.parseNmcli).find(parts => parts[1] === "wifi")
                root.wifiDevice = row ? row[0] : ""
                const wired = text.split("\n").map(root.parseNmcli).find(parts => parts[1] === "ethernet")
                root.ethernetDevice = wired ? wired[0] : ""
                root.ethernetConnected = wired ? wired[2].startsWith("connected") : false
            }
        }
    }
    Process {
        id: wifiList
        command: ["env", "LC_ALL=C", "nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.networks = text.split("\n").filter(Boolean).map(root.parseNmcli)
                    .filter(parts => parts[1]).map(parts => ({
                        active: parts[0] === "*", ssid: parts[1],
                        signal: parseInt(parts[2]) || 0,
                        security: parts[3] && parts[3] !== "--" ? parts[3] : ""
                    })).filter((item, index, all) => all.findIndex(other => other.ssid === item.ssid) === index)
                    .sort((a, b) => Number(b.active) - Number(a.active) || b.signal - a.signal)
                const active = root.networks.find(item => item.active)
                root.activeSsid = active?.ssid || ""
                root.signalStrength = active?.signal || 0
            }
        }
    }
    Process {
        id: bluetoothState
        command: ["sh", "-c", "command -v bluetoothctl >/dev/null || exit 1; bluetoothctl show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.bluetoothAvailable = text.includes("Controller ")
                root.bluetoothEnabled = /Powered:\s+yes/.test(text)
            }
        }
    }
    Process {
        id: bluetoothList
        command: ["sh", "-c", "bluetoothctl devices 2>/dev/null | while read -r kind address name; do info=$(bluetoothctl info \"$address\" 2>/dev/null); connected=$(printf '%s' \"$info\" | sed -n 's/.*Connected: //p' | head -1); paired=$(printf '%s' \"$info\" | sed -n 's/.*Paired: //p' | head -1); battery=$(printf '%s' \"$info\" | sed -n 's/.*Battery Percentage:.*(\\([0-9]*\\)).*/\\1/p' | head -1); printf '%s\\t%s\\t%s\\t%s\\t%s\\n' \"$address\" \"$name\" \"$connected\" \"$paired\" \"$battery\"; done"]
        stdout: StdioCollector {
            onStreamFinished: root.bluetoothDevices = text.trim().split("\n").filter(Boolean).map(line => {
                const parts = line.split("\t")
                return { address: parts[0], name: parts[1], connected: parts[2] === "yes", paired: parts[3] === "yes", battery: parts[4] }
            }).sort((a,b) => Number(b.paired) - Number(a.paired) || a.name.localeCompare(b.name))
        }
    }
    Process {
        id: brightnessRead
        command: ["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                root.brightnessAvailable = parts.length >= 4
                if (root.brightnessAvailable) root.brightness = parseInt(parts[3]) || 0
            }
        }
    }
    Process {
        id: weatherRead
        command: ["curl", "-fsS", "--max-time", "8", "https://wttr.in/" + encodeURIComponent(root.weatherCity) + "?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.weather = JSON.parse(text); root.weatherError = "" }
                catch (error) { root.weather = null; root.weatherError = "Météo indisponible" }
            }
        }
    }
    Process {
        id: profileCheck
        command: ["sh", "-c", "command -v powerprofilesctl >/dev/null && echo yes"]
        stdout: StdioCollector { onStreamFinished: root.profileAvailable = text.trim() === "yes" }
    }
    Process {
        id: batteryRead
        command: ["sh", "-c", "for b in /sys/class/power_supply/BAT*; do [ -f \"$b/capacity\" ] || continue; cat \"$b/capacity\" \"$b/status\"; now=$(cat \"$b/energy_now\" 2>/dev/null || cat \"$b/charge_now\" 2>/dev/null); full=$(cat \"$b/energy_full\" 2>/dev/null || cat \"$b/charge_full\" 2>/dev/null); rate=$(cat \"$b/power_now\" 2>/dev/null || cat \"$b/current_now\" 2>/dev/null); printf '%s\\n%s\\n%s\\n' \"$now\" \"$full\" \"$rate\"; break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                root.batteryPresent = lines.length >= 3 && lines[0] !== ""
                if (!root.batteryPresent) return
                root.batteryPercent = parseInt(lines[0]) || 0
                root.batteryCharging = lines[1] === "Charging"
                const now = parseFloat(lines[2]) || 0
                const full = parseFloat(lines[3]) || 0
                const rate = parseFloat(lines[4]) || 0
                root.batteryTime = rate > 0 ? Math.round((root.batteryCharging ? full - now : now) / rate * 3600) : 0
            }
        }
    }
    Timer { interval: 30000; running: root.open; repeat: true; onTriggered: root.refresh() }
    Timer { interval: 1800000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weatherRead.running = true }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: batteryRead.running = true }
    Component.onCompleted: {
        profileCheck.running = true
        nightCheck.running = true
    }

    PanelWindow {
        screen: root.targetScreen
        visible: root.open
        anchors { top: true; right: true }
        margins { top: root.barInset + 8; right: root.popupRight }
        implicitWidth: Math.min(root.page === "calendar" ? 360 : 400, screen.width - 20)
        implicitHeight: Math.min(screen.height - root.barInset - 20,
            Math.max(190, content.implicitHeight + headerRow.implicitHeight + tabFlow.implicitHeight + 44))
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: root.colors.cSurface
            border.width: 1
            border.color: root.colors.cBorder
            focus: root.open
            Keys.onEscapePressed: root.open = false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                RowLayout {
                    id: headerRow
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: ({audio:"Audio",network:"Réseau",bluetooth:"Bluetooth",battery:"Batterie",brightness:"Luminosité",calendar:"Calendrier",weather:"Météo",media:"Multimédia"})[root.page]
                        color: root.colors.cText; font.pixelSize: 14; font.bold: true
                    }
                    Text {
                        text: "✕"; color: root.colors.cMuted; font.pixelSize: 14
                        MouseArea { anchors.fill: parent; onClicked: root.open = false }
                    }
                }
                Flow {
                    id: tabFlow
                    Layout.fillWidth: true
                    spacing: 5
                    Repeater {
                        model: [
                            {id:"audio",label:"Son"},{id:"network",label:"Réseau"},{id:"bluetooth",label:"BT"},
                            {id:"battery",label:"Batterie"},{id:"brightness",label:"Écran"},{id:"calendar",label:"Date"},
                            {id:"weather",label:"Météo"},{id:"media",label:"Média"}
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: tabText.implicitWidth + 16; height: 28; radius: 4
                            color: root.page === modelData.id ? root.colors.cSelection : root.colors.cElevated
                            Text { id: tabText; anchors.centerIn: parent; text: modelData.label; color: root.page === modelData.id ? root.colors.cAccent : root.colors.cMuted; font.pixelSize: 11 }
                            MouseArea { anchors.fill: parent; onClicked: root.showPanel(modelData.id, root.targetScreen) }
                        }
                    }
                }
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentWidth: width; contentHeight: content.implicitHeight
                    clip: true
                    ColumnLayout {
                        id: content
                        width: parent.width; spacing: 10

                        ColumnLayout {
                            visible: root.page === "audio"; Layout.fillWidth: true; spacing: 8
                            Text { text: "Sortie · " + (root.sink?.description || "Aucune"); color: root.colors.cText; font.pixelSize: 12 }
                            PanelSlider { Layout.fillWidth: true; from: 0; to: 1; value: root.sink?.audio?.volume || 0; enabled: !!root.sink?.audio; onMoved: root.sink.audio.volume = value }
                            PanelButton { text: root.sink?.audio?.muted ? "Réactiver la sortie" : "Couper la sortie"; enabled: !!root.sink?.audio; onClicked: root.sink.audio.muted = !root.sink.audio.muted }
                            Text { text: "Périphériques de sortie"; color: root.colors.cMuted; font.pixelSize: 11 }
                            Repeater {
                                model: root.audioNodes.filter(n => n.isSink && !n.isStream)
                                delegate: PanelButton { required property var modelData; Layout.fillWidth: true; text: (root.sink?.id === modelData.id ? "●  " : "○  ") + (modelData.description || modelData.name); onClicked: Pipewire.preferredDefaultAudioSink = modelData }
                            }
                            Rectangle { Layout.fillWidth: true; height: 1; color: root.colors.cBorder }
                            Text { text: "Microphone · " + (root.source?.description || "Aucun"); color: root.colors.cText; font.pixelSize: 12 }
                            PanelSlider { Layout.fillWidth: true; from: 0; to: 1; value: root.source?.audio?.volume || 0; enabled: !!root.source?.audio; onMoved: root.source.audio.volume = value }
                            PanelButton { text: root.source?.audio?.muted ? "Réactiver le micro" : "Couper le micro"; enabled: !!root.source?.audio; onClicked: root.source.audio.muted = !root.source.audio.muted }
                            Repeater {
                                model: root.audioNodes.filter(n => !n.isSink && !n.isStream)
                                delegate: PanelButton { required property var modelData; Layout.fillWidth: true; text: (root.source?.id === modelData.id ? "●  " : "○  ") + (modelData.description || modelData.name); onClicked: Pipewire.preferredDefaultAudioSource = modelData }
                            }
                            Text { text: "Mixeur par application"; color: root.colors.cMuted; font.pixelSize: 11 }
                            Repeater {
                                model: root.audioNodes.filter(n => n.isStream)
                                delegate: ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Text { text: modelData.description || modelData.name; color: root.colors.cText; font.pixelSize: 11 }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        PanelButton { text: modelData.audio?.muted ? "" : ""; onClicked: modelData.audio.muted = !modelData.audio.muted }
                                        PanelSlider { Layout.fillWidth: true; from: 0; to: 1; value: modelData.audio?.volume || 0; onMoved: modelData.audio.volume = value }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            visible: root.page === "network"; Layout.fillWidth: true; spacing: 8
                            Text { text: root.ethernetDevice ? "Ethernet · " + root.ethernetDevice + (root.ethernetConnected ? " · connecté" : " · déconnecté") : "Aucun adaptateur Ethernet"; color: root.colors.cMuted; font.pixelSize: 11 }
                            Text { text: root.activeSsid ? "Connecté à " + root.activeSsid + " · " + root.signalStrength + "%" : "Aucun Wi-Fi actif"; color: root.colors.cText; font.pixelSize: 12 }
                            PanelButton { text: root.wifiEnabled ? "Désactiver le Wi-Fi" : "Activer le Wi-Fi"; onClicked: { root.run(["nmcli","radio","wifi",root.wifiEnabled ? "off" : "on"]); refreshDelay.restart() } }
                            Text { text: "Réseaux disponibles"; color: root.colors.cMuted; font.pixelSize: 11 }
                            Repeater {
                                model: root.networks
                                delegate: PanelButton {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    text: (modelData.active ? "●  " : "○  ") + modelData.ssid + " · " + modelData.signal + "%" + (modelData.security ? "  " : "")
                                    onClicked: {
                                        if (modelData.active) root.run(["nmcli","device","disconnect",root.wifiDevice])
                                        else if (modelData.security) root.pendingSsid = modelData.ssid
                                        else root.run(["nmcli","device","wifi","connect",modelData.ssid])
                                        refreshDelay.restart()
                                    }
                                }
                            }
                            TextField { id: wifiPassword; visible: root.pendingSsid !== ""; Layout.fillWidth: true; placeholderText: "Mot de passe · " + root.pendingSsid; placeholderTextColor: root.colors.cMuted; color: root.colors.cText; echoMode: TextInput.Password; onAccepted: root.connectWifi(); background: Rectangle { radius: 4; color: root.colors.cElevated } }
                            PanelButton { visible: root.pendingSsid !== ""; text: "Connecter"; onClicked: root.connectWifi() }
                            PanelButton { text: "Rechercher les réseaux"; onClicked: { root.run(["nmcli","device","wifi","rescan"]); refreshDelay.restart() } }
                        }

                        ColumnLayout {
                            visible: root.page === "bluetooth"; Layout.fillWidth: true; spacing: 8
                            Text { text: root.bluetoothAvailable ? (root.bluetoothEnabled ? "Bluetooth activé" : "Bluetooth désactivé") : "Bluetooth indisponible · BlueZ requis"; color: root.colors.cText; font.pixelSize: 12 }
                            PanelButton { text: root.bluetoothEnabled ? "Désactiver" : "Activer"; enabled: root.bluetoothAvailable; onClicked: { root.run(["bluetoothctl","power",root.bluetoothEnabled ? "off" : "on"]); refreshDelay.restart() } }
                            PanelButton { text: "Rechercher des appareils"; enabled: root.bluetoothAvailable; onClicked: { root.run(["bluetoothctl","--timeout","10","scan","on"]); bluetoothScanDelay.restart() } }
                            Text { text: "Appareils appairés et détectés"; color: root.colors.cMuted; font.pixelSize: 11 }
                            Repeater {
                                model: root.bluetoothDevices
                                delegate: PanelButton {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    text: (modelData.connected ? "●  " : modelData.paired ? "○  " : "+  ") + modelData.name + (modelData.battery ? " · " + modelData.battery + "%" : "")
                                    onClicked: {
                                        if (modelData.paired) root.run(["bluetoothctl",modelData.connected ? "disconnect" : "connect",modelData.address])
                                        else root.run(["sh","-c","bluetoothctl pair \"$1\" && bluetoothctl connect \"$1\"", "qs-bt", modelData.address])
                                        refreshDelay.restart()
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            visible: root.page === "battery"; Layout.fillWidth: true; spacing: 10
                            Text { text: root.battery?.isPresent ? Math.round(root.battery.percentage * 100) + "%" : root.batteryPresent ? root.batteryPercent + "%" : "Batterie indisponible"; color: root.colors.cText; font.pixelSize: 24; font.bold: true }
                            Text { visible: root.battery?.isPresent || root.batteryPresent; text: (root.battery?.isPresent ? (UPower.onBattery ? "Sur batterie · " : "Sur secteur · ") : root.batteryCharging ? "En charge · " : "Sur batterie · ") + root.duration(root.battery?.isPresent ? (UPower.onBattery ? root.battery.timeToEmpty : root.battery.timeToFull) : root.batteryTime); color: root.colors.cMuted; font.pixelSize: 12 }
                            Text { text: "Profil énergétique"; color: root.colors.cText; font.pixelSize: 12 }
                            Text { visible: !root.profileAvailable; text: "Service de profils énergétiques indisponible"; color: root.colors.cMuted; font.pixelSize: 11 }
                            Repeater {
                                model: [{name:"Économie",value:PowerProfile.PowerSaver},{name:"Équilibré",value:PowerProfile.Balanced},{name:"Performance",value:PowerProfile.Performance}]
                                delegate: PanelButton { required property var modelData; Layout.fillWidth: true; text: (PowerProfiles.profile === modelData.value ? "●  " : "○  ") + modelData.name; enabled: root.profileAvailable && (modelData.value !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile); onClicked: PowerProfiles.profile = modelData.value }
                            }
                        }

                        ColumnLayout {
                            visible: root.page === "brightness"; Layout.fillWidth: true; spacing: 9
                            Text { text: root.brightnessAvailable ? "Luminosité · " + root.brightness + "%" : "Luminosité indisponible · brightnessctl requis"; color: root.colors.cText; font.pixelSize: 12 }
                            PanelSlider { Layout.fillWidth: true; from: 1; to: 100; value: root.brightness; enabled: root.brightnessAvailable; onMoved: { root.brightness = Math.round(value); root.run(["brightnessctl","set",root.brightness + "%"]) } }
                            PanelButton { text: "Night Light"; enabled: root.nightLightAvailable; onClicked: root.toggleNightLight() }
                            Text { text: root.nightLightAvailable ? (root.nightLight ? "Actif" : "Inactif") : "hyprsunset requis"; color: root.colors.cMuted; font.pixelSize: 11 }
                        }

                        ColumnLayout {
                            visible: root.page === "calendar"; Layout.fillWidth: true; spacing: 8
                            RowLayout {
                                Layout.fillWidth: true
                                PanelButton { text: "‹"; onClicked: root.monthOffset-- }
                                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(new Date(new Date().getFullYear(), new Date().getMonth() + root.monthOffset, 1), "MMMM yyyy"); color: root.colors.cText; font.pixelSize: 14 }
                                PanelButton { text: "›"; onClicked: root.monthOffset++ }
                            }
                            GridLayout {
                                id: calendarGrid
                                Layout.preferredWidth: Math.min(content.width, 350)
                                Layout.alignment: Qt.AlignHCenter
                                columns: 7; columnSpacing: 0; rowSpacing: 4
                                Repeater { model: ["L","M","M","J","V","S","D"]; delegate: Text { required property string modelData; Layout.preferredWidth: calendarGrid.width / 7; horizontalAlignment: Text.AlignHCenter; text: modelData; color: root.colors.cMuted; font.pixelSize: 11 } }
                                Repeater {
                                    model: 42
                                    delegate: Rectangle {
                                        required property int index
                                        readonly property date first: new Date(new Date().getFullYear(), new Date().getMonth() + root.monthOffset, 1)
                                        readonly property int offset: (first.getDay() + 6) % 7
                                        readonly property date day: new Date(first.getFullYear(), first.getMonth(), index - offset + 1)
                                        readonly property bool today: day.toDateString() === new Date().toDateString()
                                        Layout.preferredWidth: calendarGrid.width / 7; Layout.preferredHeight: 36; radius: 6
                                        color: today ? root.colors.cSelection : "transparent"
                                        Text { anchors.centerIn: parent; text: day.getDate(); color: today ? root.colors.cAccent : day.getMonth() === first.getMonth() ? root.colors.cText : root.colors.cMuted; font.pixelSize: 11 }
                                    }
                                }
                            }
                            PanelButton { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 120; text: "Aujourd’hui"; onClicked: root.monthOffset = 0 }
                        }

                        ColumnLayout {
                            visible: root.page === "weather"; Layout.fillWidth: true; spacing: 9
                            Text { text: root.weatherCity; color: root.colors.cText; font.pixelSize: 14; font.bold: true }
                            TextField {
                                Layout.fillWidth: true
                                text: root.weatherCity
                                placeholderText: "Ville"
                                placeholderTextColor: root.colors.cMuted
                                color: root.colors.cText
                                onAccepted: {
                                    const city = text.trim()
                                    if (!city) return
                                    root.weatherCity = city
                                    settingsStore.city = city
                                    settingsFile.writeAdapter()
                                    weatherRead.running = true
                                }
                                background: Rectangle { radius: 4; color: root.colors.cElevated }
                            }
                            Text { text: root.weather?.current_condition?.[0] ? root.weather.current_condition[0].temp_C + " °C" : root.weatherError || "Chargement…"; color: root.colors.cAccent; font.pixelSize: 24 }
                            Text { text: root.weather?.current_condition?.[0]?.lang_fr?.[0]?.value || root.weather?.current_condition?.[0]?.weatherDesc?.[0]?.value || ""; color: root.colors.cMuted; font.pixelSize: 12 }
                            Repeater {
                                model: root.weather?.weather || []
                                delegate: RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: modelData.date; color: root.colors.cText; font.pixelSize: 12 }
                                    Text { text: modelData.mintempC + "° / " + modelData.maxtempC + "°"; color: root.colors.cMuted; font.pixelSize: 12 }
                                }
                            }
                            PanelButton { text: "Actualiser"; onClicked: weatherRead.running = true }
                        }

                        ColumnLayout {
                            visible: root.page === "media"; Layout.fillWidth: true; spacing: 10
                            Image { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 128; Layout.preferredHeight: 128; source: root.player?.trackArtUrl || ""; fillMode: Image.PreserveAspectCrop; visible: source !== "" }
                            Text { Layout.fillWidth: true; text: root.player?.trackTitle || "Aucune lecture"; color: root.colors.cText; font.pixelSize: 15; font.bold: true; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; text: root.player?.trackArtist || ""; color: root.colors.cMuted; font.pixelSize: 12; elide: Text.ElideRight }
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                PanelButton { text: "⏮"; enabled: !!root.player?.canGoPrevious; onClicked: root.player.previous() }
                                PanelButton { text: root.player?.isPlaying ? "⏸" : "▶"; enabled: !!root.player?.canTogglePlaying; onClicked: root.player.togglePlaying() }
                                PanelButton { text: "⏭"; enabled: !!root.player?.canGoNext; onClicked: root.player.next() }
                            }
                            PanelSlider { Layout.fillWidth: true; from: 0; to: Math.max(1, root.player?.length || 1); value: root.player?.position || 0; enabled: !!root.player?.canSeek; onMoved: root.player.position = value }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: root.clockTime(root.player?.position); color: root.colors.cMuted; font.pixelSize: 11 }
                                Item { Layout.fillWidth: true }
                                Text { text: root.clockTime(root.player?.length); color: root.colors.cMuted; font.pixelSize: 11 }
                            }
                        }
                    }
                }
            }
        }
    }
    Timer { id: refreshDelay; interval: 1300; onTriggered: root.refresh() }
    Timer { id: bluetoothScanDelay; interval: 10500; onTriggered: bluetoothList.running = true }
    property bool nightLight: false
    property bool nightLightAvailable: false
    Process { id: nightCheck; command: ["sh","-c","command -v hyprsunset >/dev/null && echo yes"]; stdout: StdioCollector { onStreamFinished: root.nightLightAvailable = text.trim() === "yes" } }
    function toggleNightLight() {
        if (!nightLightAvailable) return
        nightLight = !nightLight
        if (nightLight) {
            run(["hyprsunset"])
            nightApply.restart()
        } else run(["hyprctl", "hyprsunset", "identity"])
    }
    Timer { id: nightApply; interval: 600; onTriggered: root.run(["hyprctl", "hyprsunset", "temperature", "4500"]) }
}

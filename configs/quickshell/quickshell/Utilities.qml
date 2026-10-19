import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
    id: root
    required property var colors
    property bool open: false
    property string mode: "emoji"
    property string directory: Quickshell.env("HOME") || "/"
    property var files: []
    property string selectedFile: ""
    property string confirmation: ""
    onOpenChanged: {
        if (open) Qt.callLater(() => mode === "power" ? list.forceActiveFocus() : search.forceActiveFocus())
    }
    readonly property var emojis: [
        {icon:"😀",name:"sourire"},{icon:"😄",name:"joyeux"},{icon:"😂",name:"rire"},{icon:"🥲",name:"ému"},
        {icon:"😍",name:"amour"},{icon:"🥰",name:"cœur"},{icon:"😘",name:"bisou"},{icon:"😎",name:"cool"},
        {icon:"🤔",name:"réflexion"},{icon:"🙃",name:"ironie"},{icon:"😭",name:"pleurs"},{icon:"😱",name:"surpris"},
        {icon:"😴",name:"sommeil"},{icon:"🤯",name:"cerveau"},{icon:"👍",name:"pouce haut"},{icon:"👎",name:"pouce bas"},
        {icon:"👏",name:"applaudir"},{icon:"🙏",name:"merci"},{icon:"👋",name:"bonjour"},{icon:"🤝",name:"accord"},
        {icon:"💪",name:"force"},{icon:"👌",name:"ok"},{icon:"✌️",name:"victoire"},{icon:"❤️",name:"cœur rouge"},
        {icon:"💜",name:"cœur violet"},{icon:"🔥",name:"feu"},{icon:"✨",name:"étoiles"},{icon:"⭐",name:"étoile"},
        {icon:"⚡",name:"éclair"},{icon:"💡",name:"idée"},{icon:"🎉",name:"fête"},{icon:"🚀",name:"fusée"},
        {icon:"🐛",name:"bug"},{icon:"🐧",name:"linux"},{icon:"💻",name:"ordinateur"},{icon:"⌨️",name:"clavier"},
        {icon:"🔧",name:"outil"},{icon:"🔒",name:"verrou"},{icon:"✅",name:"validé"},{icon:"❌",name:"erreur"},
        {icon:"⚠️",name:"attention"},{icon:"📌",name:"épingle"},{icon:"📋",name:"presse-papiers"},{icon:"📁",name:"dossier"},
        {icon:"🎵",name:"musique"},{icon:"☕",name:"café"},{icon:"🌙",name:"lune"},{icon:"☀️",name:"soleil"},
        {icon:"🌧️",name:"pluie"},{icon:"❄️",name:"neige"},{icon:"🌍",name:"terre"},{icon:"🍕",name:"pizza"}
    ]
    readonly property var powerActions: [
        {name:"Verrouiller",icon:"",key:"lock"},
        {name:"Mettre en veille",icon:"",key:"suspend"},
        {name:"Redémarrer",icon:"",key:"reboot"},
        {name:"Éteindre",icon:"",key:"poweroff"},
        {name:"Se déconnecter",icon:"",key:"logout"}
    ]

    function showMode(name) {
        mode = name
        confirmation = ""
        selectedFile = ""
        open = true
        if (name === "files") fileProc.running = true
    }
    function activate(entry) {
        if (!entry) return
        if (mode === "emoji") {
            Quickshell.clipboardText = entry.icon
            open = false
        } else if (mode === "files") {
            if (entry.directory) {
                directory = entry.path
                fileProc.running = true
            } else {
                selectedFile = entry.path
                Quickshell.clipboardText = entry.path
                open = false
            }
        } else if (mode === "power") {
            if (entry.key === "lock") {
                Quickshell.execDetached(["qs","ipc","call","session","lock"])
                open = false
            } else if (entry.key === "suspend") {
                Quickshell.execDetached(["qs","ipc","call","session","suspend"])
                open = false
            } else if (confirmation !== entry.key) confirmation = entry.key
            else {
                if (entry.key === "logout") Quickshell.execDetached(["hyprctl","dispatch","exit"])
                else Quickshell.execDetached(["systemctl",entry.key])
                open = false
            }
        }
    }

    IpcHandler {
        target: "utilities"
        function emoji(): void { root.showMode("emoji") }
        function files(): void { root.showMode("files") }
        function power(): void { root.showMode("power") }
        function hide(): void { root.open = false }
    }

    Process {
        id: fileProc
        command: ["sh","-c","find \"$1\" -mindepth 1 -maxdepth 1 -printf '%y\\t%f\\n' 2>/dev/null", "qs-files", root.directory]
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = text.split("\n").filter(Boolean).map(line => {
                    const parts = line.split("\t")
                    const name = parts.slice(1).join("\t")
                    return {name:name, path:root.directory.replace(/\/$/, "") + "/" + name, directory:parts[0] === "d"}
                }).sort((a,b) => Number(b.directory) - Number(a.directory) || a.name.localeCompare(b.name))
            }
        }
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
        visible: root.open
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        MouseArea { anchors.fill: parent; onClicked: root.open = false }

        Rectangle {
            width: Math.min(510, parent.width - 32)
            height: Math.min(root.mode === "power" ? 390 : 570, parent.height - 32)
            anchors.centerIn: parent
            color: root.colors.cSurface
            border.width: 1
            border.color: root.colors.cBorder
            radius: 14
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: root.mode === "emoji" ? "Émojis" : root.mode === "files" ? "Fichiers" : "Alimentation"; color: root.colors.cText; font.pixelSize: 16; font.bold: true }
                    Text { text: "Échap"; color: root.colors.cMuted; font.pixelSize: 10 }
                }
                Text {
                    visible: root.mode === "files"
                    Layout.fillWidth: true
                    text: root.directory
                    elide: Text.ElideMiddle
                    color: root.colors.cMuted
                    font.pixelSize: 11
                }
                TextField {
                    id: search
                    visible: root.mode !== "power"
                    Layout.fillWidth: true
                    placeholderText: root.mode === "emoji" ? "Chercher un émoji…" : "Filtrer les fichiers…"
                    placeholderTextColor: root.colors.cMuted
                    color: root.colors.cText
                    background: Rectangle { radius: 8; color: root.colors.cElevated }
                    onTextChanged: list.currentIndex = 0
                    onAccepted: root.activate(list.currentItem?.modelData)
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onEscapePressed: root.open = false
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Backspace && root.mode === "files" && text === "" && root.directory !== "/") {
                            root.directory = root.directory.slice(0, root.directory.lastIndexOf("/")) || "/"
                            fileProc.running = true
                        } else event.accepted = false
                    }
                    Component.onCompleted: forceActiveFocus()
                }
                ListView {
                    id: list
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; spacing: 5
                    currentIndex: 0
                    focus: root.open && root.mode === "power"
                    Keys.onUpPressed: decrementCurrentIndex()
                    Keys.onDownPressed: incrementCurrentIndex()
                    Keys.onReturnPressed: root.activate(currentItem?.modelData)
                    Keys.onEnterPressed: root.activate(currentItem?.modelData)
                    Keys.onEscapePressed: root.open = false
                    model: root.mode === "emoji"
                        ? root.emojis.filter(e => (e.name + e.icon).toLowerCase().includes(search.text.toLowerCase()))
                        : root.mode === "files"
                            ? [{name:"..",path:root.directory.slice(0,root.directory.lastIndexOf("/")) || "/",directory:true}]
                                .concat(root.files.filter(e => e.name.toLowerCase().includes(search.text.toLowerCase())))
                            : root.powerActions
                    delegate: Rectangle {
                        required property var modelData
                        width: list.width; height: 43; radius: 7
                        color: ListView.isCurrentItem || rowMouse.containsMouse ? root.colors.cSelection : root.colors.cElevated
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
                            Text { text: root.mode === "emoji" ? modelData.icon : root.mode === "files" ? (modelData.directory ? "" : "") : modelData.icon; color: root.colors.cAccent; font.family: root.mode === "emoji" ? "sans-serif" : "JetBrainsMono Nerd Font"; font.pixelSize: 17 }
                            Text { Layout.fillWidth: true; text: modelData.name; color: root.colors.cText; font.pixelSize: 12; elide: Text.ElideRight }
                            Text { visible: root.mode === "power" && root.confirmation === modelData.key; text: "Confirmer"; color: root.colors.cWarning; font.pixelSize: 10 }
                        }
                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton && root.mode === "files" && !modelData.directory) {
                                    Quickshell.execDetached(["xdg-open", modelData.path])
                                    root.open = false
                                } else root.activate(modelData)
                            }
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.mode === "emoji" ? "Sélection : copie dans le presse-papiers" : root.mode === "files" ? "Clic : copier le chemin · clic droit : ouvrir · Retour arrière : parent" : "Redémarrer, éteindre et déconnecter demandent confirmation"
                    color: root.colors.cMuted; font.pixelSize: 10; wrapMode: Text.WordWrap
                }
            }
        }
    }
}

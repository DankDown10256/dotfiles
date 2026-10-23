import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    required property var colors
    property bool open: false
    property bool alive: false
    property var availableTools: []
    property var recentProjects: projectStore.projects
    property string selectedPath: ""
    property string gitSummary: "Choisis un projet pour consulter son état Git."
    property string portSummary: ""
    property string dockerSummary: ""
    property string podmanSummary: ""

    readonly property var terminals: ["kitty", "foot", "alacritty"]
    readonly property var editors: ["code", "codium", "nvim"]

    function rememberProject(path) {
        if (!path || path.length === 0) return
        gitRootProc.command = ["git", "-C", path, "rev-parse", "--show-toplevel"]
        gitRootProc.running = true
    }

    function inspectProject(path) {
        root.selectedPath = path
        root.gitSummary = "Lecture de l’état Git…"
        gitProc.command = ["git", "-C", path, "status", "--short", "--branch"]
        gitProc.running = true
    }

    function openTerminal(path) {
        if (availableTools.includes("kitty"))
            Quickshell.execDetached(["kitty", "--directory", path])
        else if (availableTools.includes("foot"))
            Quickshell.execDetached(["foot", "--working-directory", path])
        else if (availableTools.includes("alacritty"))
            Quickshell.execDetached(["alacritty", "--working-directory", path])
    }

    function openEditor(path) {
        if (availableTools.includes("code"))
            Quickshell.execDetached(["code", "--new-window", path])
        else if (availableTools.includes("codium"))
            Quickshell.execDetached(["codium", "--new-window", path])
        else if (availableTools.includes("nvim")) {
            if (availableTools.includes("kitty"))
                Quickshell.execDetached(["kitty", "--directory", path, "nvim", "."])
            else if (availableTools.includes("foot"))
                Quickshell.execDetached(["foot", "--working-directory", path, "nvim", "."])
            else if (availableTools.includes("alacritty"))
                Quickshell.execDetached(["alacritty", "--working-directory", path, "-e", "nvim", "."])
        }
    }

    function openWorkspace(path) {
        root.openEditor(path)
        if (availableTools.includes("code") || availableTools.includes("codium"))
            root.openTerminal(path)
    }

    function refresh() {
        availabilityProc.running = true
        portsProc.running = true
        if (availableTools.includes("docker")) dockerProc.running = true
        if (availableTools.includes("podman")) podmanProc.running = true
    }

    FileView {
        id: projectFile
        path: Quickshell.stateDir + "/recent-projects.json"
        printErrors: false
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: projectStore
            property var projects: []
        }
    }

    IpcHandler {
        target: "devtools"
        function toggle(): void {
            root.open = !root.open
            if (root.open) root.refresh()
        }
        function show(): void { root.open = true; root.refresh() }
        function hide(): void { root.open = false }
        function remember(path: string): void { root.rememberProject(path) }
    }

    Process {
        id: availabilityProc
        command: ["sh", "-c", "for tool in git code codium nvim kitty foot alacritty docker podman ss; do command -v \"$tool\" >/dev/null 2>&1 && echo \"$tool\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.availableTools = text.split("\n").map(item => item.trim()).filter(item => item !== "")
                if (root.open) {
                    if (root.availableTools.includes("docker")) dockerProc.running = true
                    if (root.availableTools.includes("podman")) podmanProc.running = true
                }
            }
        }
    }

    Process {
        id: gitProc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length === 0 || lines[0] === "") {
                    root.gitSummary = "Dépôt Git indisponible."
                    return
                }
                root.gitSummary = lines[0].replace(/^##\s*/, "")
                    + (lines.length > 1 ? " · " + (lines.length - 1) + " modification(s)" : " · propre")
            }
        }
    }

    Process {
        id: gitRootProc
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                if (path === "") return
                const name = path.substring(path.lastIndexOf("/") + 1)
                const next = [{ name: name, path: path }]
                    .concat(root.recentProjects.filter(entry => entry.path !== path)).slice(0, 12)
                projectStore.projects = next
            }
        }
    }

    Process {
        id: portsProc
        command: ["ss", "-ltnH"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = text.trim().split("\n").filter(line => line !== "")
                root.portSummary = rows.slice(0, 12).map(line => {
                    const columns = line.trim().split(/\s+/)
                    return columns[3] || line.trim()
                }).join("\n")
            }
        }
    }

    Process {
        id: dockerProc
        command: ["sh", "-c", "docker ps --format '{{.Names}} · {{.Status}}' 2>&1 || true"]
        stdout: StdioCollector {
            onStreamFinished: root.dockerSummary = text.trim()
        }
    }

    Process {
        id: podmanProc
        command: ["sh", "-c", "podman ps --format '{{.Names}} · {{.Status}}' 2>&1 || true"]
        stdout: StdioCollector {
            onStreamFinished: root.podmanSummary = text.trim()
        }
    }

    onOpenChanged: {
        if (open) {
            alive = true
            closeTimer.stop()
            refresh()
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
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            MouseArea { anchors.fill: parent; onClicked: root.open = false }

            Rectangle {
                id: card
                width: Math.min(900, parent.width - 32)
                height: Math.min(560, parent.height - 32)
                anchors.centerIn: parent
                radius: 6
                color: root.colors.cSurface
                border.width: 1
                border.color: root.colors.cBorder
                opacity: root.open ? 1 : 0
                scale: root.open ? 1 : 0.98
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150 } }
                MouseArea { anchors.fill: parent }
                Keys.onEscapePressed: root.open = false
                focus: root.open

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Espace développeur"; color: root.colors.cText; font.pixelSize: 14; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: "Git · terminaux · services locaux"; color: root.colors.cMuted; font.pixelSize: 11 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: 5
                            radius: 6
                            color: root.colors.cElevated

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8
                                Text { text: "Projets récents"; color: root.colors.cText; font.pixelSize: 12; font.bold: true }
                                Text {
                                    Layout.fillWidth: true
                                    visible: root.recentProjects.length === 0
                                    text: "Ouvre un projet depuis le launcher pour l’ajouter ici."
                                    color: root.colors.cMuted
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                }
                                ListView {
                                    id: projectList
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    spacing: 4
                                    model: root.recentProjects
                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index
                                        width: projectList.width
                                        height: 48
                                        radius: 4
                                        color: root.selectedPath === modelData.path
                                            ? root.colors.cSelection : projectMouse.containsMouse
                                                ? root.colors.cSurface : "transparent"
                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 2
                                            Text { text: modelData.name; color: root.colors.cText; font.pixelSize: 12; font.bold: true }
                                            Text { Layout.fillWidth: true; text: modelData.path; color: root.colors.cMuted; font.pixelSize: 11; elide: Text.ElideMiddle }
                                        }
                                        MouseArea {
                                            id: projectMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.inspectProject(modelData.path)
                                        }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        radius: 4
                                        color: editorMouse.containsMouse ? root.colors.cSelection : root.colors.cSurface
                                        Text { anchors.centerIn: parent; text: "Éditeur"; color: root.colors.cText; font.pixelSize: 11 }
                                        MouseArea { id: editorMouse; anchors.fill: parent; hoverEnabled: true; enabled: root.selectedPath !== "" && root.availableTools.some(tool => root.editors.includes(tool)); onClicked: root.openEditor(root.selectedPath) }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        radius: 4
                                        color: terminalMouse.containsMouse ? root.colors.cSelection : root.colors.cSurface
                                        Text { anchors.centerIn: parent; text: "Terminal"; color: root.colors.cText; font.pixelSize: 11 }
                                        MouseArea { id: terminalMouse; anchors.fill: parent; hoverEnabled: true; enabled: root.selectedPath !== "" && root.availableTools.some(tool => root.terminals.includes(tool)); onClicked: root.openTerminal(root.selectedPath) }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        radius: 4
                                        color: workspaceMouse.containsMouse ? root.colors.cSelection : root.colors.cSurface
                                        Text { anchors.centerIn: parent; text: "Projet"; color: root.colors.cText; font.pixelSize: 11 }
                                        MouseArea { id: workspaceMouse; anchors.fill: parent; hoverEnabled: true; enabled: root.selectedPath !== ""; onClicked: root.openWorkspace(root.selectedPath) }
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: root.selectedPath === "" ? "Sélectionne un dépôt" : root.gitSummary
                                    color: root.colors.cMuted
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: 4
                            spacing: 10

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 6
                                color: root.colors.cElevated
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 7
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Ports en écoute"; color: root.colors.cText; font.pixelSize: 12; font.bold: true }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.availableTools.includes("ss") ? "ss" : "indisponible"; color: root.availableTools.includes("ss") ? root.colors.cMuted : root.colors.cWarning; font.pixelSize: 11 }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        text: root.portSummary || "Aucun port TCP en écoute."
                                        color: root.colors.cMuted
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        wrapMode: Text.Wrap
                                        verticalAlignment: Text.AlignTop
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 6
                                color: root.colors.cElevated
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 7
                                    Text { text: "Conteneurs"; color: root.colors.cText; font.pixelSize: 12; font.bold: true }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        text: (root.availableTools.includes("docker")
                                            ? "Docker\n" + (root.dockerSummary || "Aucun conteneur actif.")
                                            : "Docker indisponible")
                                            + "\n\n" + (root.availableTools.includes("podman")
                                            ? "Podman\n" + (root.podmanSummary || "Aucun conteneur actif.")
                                            : "Podman indisponible")
                                        color: root.colors.cMuted
                                        font.pixelSize: 11
                                        wrapMode: Text.Wrap
                                        verticalAlignment: Text.AlignTop
                                    }
                                }
                            }
                        }
                    }

                    Text { Layout.fillWidth: true; text: "Échap pour fermer"; color: root.colors.cMuted; font.pixelSize: 11 }
                }
            }
        }
    }
}

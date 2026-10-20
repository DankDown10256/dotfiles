import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
    id: launcher
    required property var colors
    property int barInset: 48
 
    readonly property color cBg:      colors.cBg
    readonly property color cSurface: colors.cSurface
    readonly property color cSel:     colors.cSelection
    readonly property color cAccent:  colors.cAccent
    readonly property color cText:    colors.cText
    readonly property color cDim:     colors.cMuted
    

    property bool open: false
    property bool alive: false
    property bool windowMode: false
    property bool projectMode: false
    property bool commandMode: false
    property bool unifiedMode: true
    property string pendingProject: ""
    property var projectEntries: []
    property var availableTerminals: []
    readonly property bool projectsLoading:
        projectScanner.running || terminalScanner.running

    readonly property var terminalPresets: [
        { name: "Kitty", icon: "utilities-terminal", command: ["kitty", "--directory"] },
        { name: "Foot", icon: "utilities-terminal", command: ["foot", "--working-directory"] },
        { name: "Alacritty", icon: "utilities-terminal", command: ["alacritty", "--working-directory"] },
        { name: "Konsole", icon: "utilities-terminal", command: ["konsole", "--workdir"] }
    ]

    function openProject(path, terminal) {
        Quickshell.execDetached(["qs", "ipc", "call", "devtools", "remember", path])
        Quickshell.execDetached(terminal.command.concat([path]))
        launcher.open = false
    }

    function openUnified() {
        windowMode = false
        projectMode = false
        commandMode = false
        unifiedMode = true
        pendingProject = ""
        if (open) {
            open = false
        } else {
            projectEntries = []
            availableTerminals = []
            projectScanner.running = true
            terminalScanner.running = true
            open = true
        }
    }

    readonly property var shellActions: [
        { kind: "mode", mode: "projects", name: "Projets", detail: "Rechercher un dossier projet", icon: "folder" },
        { kind: "mode", mode: "windows", name: "Fenêtres", detail: "Retrouver une fenêtre ouverte", icon: "view-restore" },
        { kind: "mode", mode: "commands", name: "Commandes", detail: "Exécuter une commande shell · préfixe >", icon: "utilities-terminal" },
        { kind: "ipc", target: "workspaceoverview", method: "toggle", name: "Espaces de travail", detail: "Aperçu des workspaces et fenêtres", icon: "view-grid" },
        { kind: "ipc", target: "devtools", method: "toggle", name: "Espace développeur", detail: "Projets récents, Git, ports et conteneurs", icon: "applications-development" },
        { kind: "ipc", target: "clipboard", method: "toggle", name: "Presse-papiers", detail: "Historique des éléments copiés", icon: "edit-paste" },
        { kind: "ipc", target: "capture", method: "toggle", name: "Capture", detail: "Capture écran et enregistrement", icon: "camera-photo" },
        { kind: "ipc", target: "capture", method: "region", name: "Capturer une région", detail: "Sélectionner une zone", icon: "camera-photo" },
        { kind: "ipc", target: "capture", method: "window", name: "Capturer une fenêtre", detail: "Fenêtre active", icon: "camera-photo" },
        { kind: "ipc", target: "capture", method: "screen", name: "Capturer l’écran", detail: "Écran entier", icon: "camera-photo" },
        { kind: "ipc", target: "capture", method: "record", name: "Enregistrer l’écran", detail: "Démarrer ou arrêter", icon: "media-record" },
        { kind: "ipc", target: "utilities", method: "emoji", name: "Émojis", detail: "Chercher et copier un émoji", icon: "face-smile" },
        { kind: "ipc", target: "utilities", method: "files", name: "Fichiers", detail: "Parcourir et copier un chemin", icon: "folder" },
        { kind: "ipc", target: "utilities", method: "power", name: "Alimentation", detail: "Verrouiller, veille, redémarrer, éteindre", icon: "system-shutdown" },
        { kind: "ipc", target: "session", method: "lock", name: "Verrouiller", detail: "Verrouiller la session", icon: "system-lock-screen" },
        { kind: "ipc", target: "session", method: "suspend", name: "Mettre en veille", detail: "Verrouiller puis suspendre", icon: "weather-clear-night" },
        { kind: "ipc", target: "bar", method: "caffeine", name: "Maintenir éveillé", detail: "Activer ou couper Caffeine", icon: "preferences-system-power-management" },
        { kind: "ipc", target: "systempanels", method: "audio", name: "Audio", detail: "Sorties, micro et mixeur", icon: "audio-volume-high" },
        { kind: "ipc", target: "systempanels", method: "network", name: "Réseau", detail: "Wi-Fi et Ethernet", icon: "network-wireless" },
        { kind: "ipc", target: "systempanels", method: "bluetooth", name: "Bluetooth", detail: "Appareils et connexions", icon: "bluetooth" },
        { kind: "ipc", target: "systempanels", method: "calendar", name: "Calendrier", detail: "Mois et date", icon: "x-office-calendar" },
        { kind: "ipc", target: "systempanels", method: "weather", name: "Météo", detail: "Conditions et prévisions", icon: "weather-clear" },
        { kind: "ipc", target: "systempanels", method: "media", name: "Multimédia", detail: "Lecteur MPRIS", icon: "media-playback-start" },
        { kind: "ipc", target: "controlcenter", method: "toggle", name: "Centre de contrôle", detail: "Wi-Fi, réseau, son, luminosité et session", icon: "preferences-system" },
        { kind: "ipc", target: "notifications", method: "toggle", name: "Notifications", detail: "Historique et mode silencieux", icon: "notifications" },
        { kind: "ipc", target: "themes", method: "toggle", name: "Thèmes", detail: "Changer le thème actif", icon: "preferences-desktop-theme" }
    ]

    function launchInTerminal(app) {
        const cwd = app.workingDirectory || Quickshell.env("HOME")
        Quickshell.execDetached(
            ["kitty", "--directory", cwd].concat(app.command)
        )
        launcher.open = false
    }

    Process {
        id: projectScanner
        command: [
            "sh", "-c",
            "for root in \"$1/Bureau\" \"$1/Desktop\"; do if [ -d \"$root\" ]; then find \"$root\" -mindepth 1 -maxdepth 1 -type d -print0; fi; done",
            "quickshell-projects", Quickshell.env("HOME")
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const paths = [...new Set(text.split("\0").filter(path => path !== ""))]
                launcher.projectEntries = paths.map(path => ({
                    name: path.substring(path.lastIndexOf("/") + 1),
                    path: path,
                    icon: "folder"
                })).sort((a, b) => a.name.localeCompare(b.name)
                    || a.path.localeCompare(b.path))
            }
        }
    }

    Process {
        id: terminalScanner
        command: [
            "sh", "-c",
            "for terminal in kitty foot alacritty konsole; do command -v \"$terminal\" >/dev/null 2>&1 && printf '%s\\n' \"$terminal\"; done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.trim().split("\n")
                launcher.availableTerminals = launcher.terminalPresets
                    .filter(terminal => names.includes(terminal.command[0]))
            }
        }
    }

    onOpenChanged: {
        if (open) { alive = true; closeTimer.stop() }
        else closeTimer.restart()
    }
    Timer {
        id: closeTimer
        interval: 200
        onTriggered: launcher.alive = false
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.openUnified() }
        function actions(): void { launcher.openUnified() }

        function windows(): void {
            if (launcher.open && launcher.windowMode) {
                launcher.open = false
            } else {
                launcher.windowMode = true
                launcher.projectMode = false
                launcher.commandMode = false
                launcher.unifiedMode = false
                launcher.open = true
            }
        }

        function projects(): void {
            if (launcher.open && launcher.projectMode) {
                launcher.open = false
            } else {
                launcher.windowMode = false
                launcher.projectMode = true
                launcher.commandMode = false
                launcher.unifiedMode = false
                launcher.pendingProject = ""
                launcher.projectEntries = []
                launcher.availableTerminals = []
                projectScanner.running = true
                terminalScanner.running = true
                launcher.open = true
            }
        }

        function commands(): void {
            launcher.windowMode = false
            launcher.projectMode = false
            launcher.commandMode = true
            launcher.unifiedMode = false
            launcher.open = true
        }
    }

    LazyLoader {
        active: launcher.alive

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: launcher.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }

            MouseArea {
                anchors.fill: parent
                onClicked: launcher.open = false
            }

            Rectangle {
                id: panel
                width: Math.min(600, parent.width - 32)
                height: Math.min(
                    144 + Math.min(results.length, 6) * 56,
                    parent.height - 48
                )
                anchors.centerIn: parent

                color: launcher.cSurface
                radius: 14
                border.width: 1
                border.color: Qt.alpha(launcher.colors.cBorder, 0.65)

                property bool shown: false
                opacity: shown ? 1 : 0

                Component.onCompleted: Qt.callLater(() => shown = launcher.open)
                Connections {
                    target: launcher
                    function onOpenChanged() { panel.shown = launcher.open }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: panel.shown ? 200 : 160
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    x: panel.shown ? 0 : -24

                    Behavior on x {
                        NumberAnimation {
                            duration: panel.shown ? 200 : 160
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea { anchors.fill: parent }

                readonly property var results: {
                    const q = search.text.trim().toLowerCase();
                    if (launcher.commandMode || (launcher.unifiedMode && q.startsWith(">"))) {
                        const command = search.text.trim().replace(/^>\s*/, "");
                        return command ? [{
                            kind: "command", name: "Exécuter : " + command,
                            detail: "Commande shell", icon: "utilities-terminal", command: command
                        }] : [];
                    }
                    if (launcher.projectMode) {
                        if (launcher.projectsLoading) return [];
                        const entries = launcher.pendingProject !== ""
                            ? launcher.availableTerminals : launcher.projectEntries;
                        return entries.filter(entry => entry.name.toLowerCase().includes(q));
                    }
                    if (launcher.windowMode) {
                        return Hyprland.toplevels.values
                            .filter(window => window.address !== "")
                            .map(window => ({
                                kind: "window",
                                name: window.title || window.lastIpcObject?.class || "Fenêtre",
                                appName: window.lastIpcObject?.class || "",
                                icon: window.wayland?.appId || "application-x-executable",
                                address: window.address,
                                workspace: window.workspace?.name || ""
                            }))
                            .filter(entry => (entry.name + " " + entry.appName)
                                .toLowerCase().includes(q))
                            .sort((a, b) => a.name.localeCompare(b.name));
                    }
                    if (!launcher.unifiedMode)
                        return DesktopEntries.applications.values
                            .filter(e => !e.noDisplay && e.name.toLowerCase().includes(q))
                            .sort((a, b) => a.name.localeCompare(b.name));

                    const actions = launcher.shellActions
                        .filter(entry => (entry.name + " " + entry.detail).toLowerCase().includes(q));
                    const apps = DesktopEntries.applications.values
                        .filter(e => !e.noDisplay && e.name.toLowerCase().includes(q))
                        .map(e => ({ kind: "app", name: e.name, icon: e.icon, desktopEntry: e }));
                    const windows = Hyprland.toplevels.values
                        .filter(window => window.address !== "")
                        .map(window => ({
                            kind: "window",
                            name: window.title || window.lastIpcObject?.class || "Fenêtre",
                            detail: window.lastIpcObject?.class || "",
                            icon: window.wayland?.appId || "application-x-executable",
                            address: window.address,
                            workspace: window.workspace?.name || ""
                        }))
                        .filter(entry => (entry.name + " " + entry.detail).toLowerCase().includes(q));
                    const projects = launcher.projectEntries
                        .filter(entry => entry.name.toLowerCase().includes(q))
                        .map(entry => ({ kind: "project", name: entry.name, detail: entry.path, icon: "folder", path: entry.path }));
                    return actions.concat(projects, windows, apps)
                        .sort((a, b) => a.name.localeCompare(b.name));
                }

                function launch(entry) {
                    if (!entry) return;
                    if (entry.kind === "mode") {
                        launcher.windowMode = entry.mode === "windows";
                        launcher.projectMode = entry.mode === "projects";
                        launcher.commandMode = entry.mode === "commands";
                        launcher.unifiedMode = false;
                        launcher.pendingProject = "";
                        search.clear();
                        if (launcher.projectMode) {
                            launcher.projectEntries = [];
                            launcher.availableTerminals = [];
                            projectScanner.running = true;
                            terminalScanner.running = true;
                        }
                        return;
                    }
                    if (entry.kind === "ipc") {
                        Quickshell.execDetached(["qs", "ipc", "call", entry.target, entry.method]);
                        launcher.open = false;
                        return;
                    }
                    if (entry.kind === "command") {
                        Quickshell.execDetached(["sh", "-lc", entry.command]);
                        launcher.open = false;
                        return;
                    }
                    if (entry.kind === "project") {
                        launcher.projectMode = true;
                        launcher.unifiedMode = false;
                        launcher.pendingProject = entry.path;
                        launcher.availableTerminals = [];
                        terminalScanner.running = true;
                        search.clear();
                        list.currentIndex = 0;
                        return;
                    }
                    if (entry.kind === "window") {
                        const window = Hyprland.toplevels.values
                            .find(window => window.address === entry.address);
                        if (!window) return;
                        const address = window.address.startsWith("0x")
                            ? window.address : "0x" + window.address;
                        Hyprland.dispatch("focuswindow address:" + address);
                        launcher.open = false;
                        return;
                    }
                    if (launcher.projectMode) {
                        if (launcher.pendingProject !== "") {
                            launcher.openProject(launcher.pendingProject, entry);
                        } else if (launcher.availableTerminals.length === 1) {
                            launcher.openProject(entry.path, launcher.availableTerminals[0]);
                        } else {
                            launcher.pendingProject = entry.path;
                            search.clear();
                            list.currentIndex = 0;
                        }
                        return;
                    }
                    if (launcher.windowMode) {
                        const window = Hyprland.toplevels.values
                            .find(window => window.address === entry.address);
                        if (!window) return;
                        const address = window.address.startsWith("0x")
                            ? window.address : "0x" + window.address;
                        Hyprland.dispatch("focuswindow address:" + address);
                        launcher.open = false;
                        return;
                    }
                    if (entry.kind === "app") {
                        entry.desktopEntry.execute();
                        launcher.open = false;
                        return;
                    }
                    if (entry.runInTerminal) {
                        launcher.launchInTerminal(entry);
                        return;
                    }
                    entry.execute();
                    launcher.open = false;
                }

                function closeWindow(entry) {
                    if (!entry || entry.kind !== "window") return;
                    const address = entry.address.startsWith("0x") ? entry.address : "0x" + entry.address;
                    Hyprland.dispatch("closewindow address:" + address);
                }
                
                function webSearch(q) {
                    const domainPattern = /^(?:https?:\/\/)?(?:[\w-]+\.)+[a-z]{2,}(?::\d+)?(?:\/\S*)?$/i;
                    const target = domainPattern.test(q)
                        ? (q.match(/^https?:\/\//i) ? q : "https://" + q)
                        : "https://duckduckgo.com/?q=" + encodeURIComponent(q);
                    Quickshell.execDetached(["xdg-open", target]);
                    launcher.open = false;
                }
                
                function youtubeSearch(q) {
                    Quickshell.execDetached(["xdg-open", "https://www.youtube.com/results?search_query=" + encodeURIComponent(q)]);
                    launcher.open = false;
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: launcher.projectMode
                                ? launcher.pendingProject !== "" ? "Choisir un terminal" : "Projets"
                                : launcher.windowMode ? "Fenêtres"
                                : launcher.commandMode ? "Commandes"
                                : launcher.unifiedMode ? "Recherche rapide" : "Applications"
                            font.family: "sans-serif"
                            font.pixelSize: 11
                            font.bold: true
                            color: launcher.cDim
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: panel.results.length + " résultats"
                            font.family: "sans-serif"
                            font.pixelSize: 11
                            color: launcher.cDim
                        }
                    }

                    TextField {
                        id: search
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        placeholderText: launcher.projectMode
                            ? launcher.pendingProject !== ""
                                ? "Ouvrir avec quel terminal ?"
                                : "Rechercher un projet…"
                            : launcher.windowMode
                            ? "Retrouver une fenêtre…"
                            : launcher.commandMode
                            ? "Saisir une commande…"
                            : launcher.unifiedMode
                            ? "Applications, projets, fenêtres et actions…  > commande"
                            : "Rechercher une application…"
                        placeholderTextColor: launcher.cDim
                        color: launcher.cText
                        selectionColor: launcher.cAccent
                        selectedTextColor: launcher.cBg
                        font.family: "sans-serif"
                        font.pixelSize: 16
                        leftPadding: 16
                        rightPadding: 16
                        background: Rectangle {
                            radius: 9
                            color: launcher.colors.cElevated
                            border.width: 1
                            border.color: search.activeFocus
                                ? Qt.alpha(launcher.cAccent, 0.3)
                                : "transparent"

                            Behavior on border.color {
                                ColorAnimation { duration: 120 }
                            }
                        }
                        Component.onCompleted: forceActiveFocus()

                        onTextChanged: list.currentIndex = 0
                        
                        onAccepted: {
                           const query = text.trim();

                           if (list.currentItem) {
                              panel.launch(list.currentItem.entry);
                           } else if (launcher.windowMode || launcher.projectMode || launcher.commandMode || query.startsWith(">")) {
                              return;
                           } else if (query.startsWith("youtube:")) {
                              const searchQuery = query.slice("youtube:".length).trim();

                              if (searchQuery !== "")
                                  panel.youtubeSearch(searchQuery);
                              } else if (query !== "") {
                                  panel.webSearch(query);
                              }
                        }

                        Keys.onEscapePressed: {
                            if (launcher.projectMode && launcher.pendingProject !== "") {
                                launcher.pendingProject = "";
                                clear();
                                list.currentIndex = 0;
                            } else {
                                launcher.open = false;
                            }
                        }
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onDeletePressed: if (launcher.windowMode) panel.closeWindow(list.currentItem?.entry)
                    }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 6
                        currentIndex: 0
                        model: ScriptModel { values: panel.results }

                        delegate: Rectangle {
                            id: item
                            required property var modelData
                            required property int index
                            readonly property var entry: modelData

                            width: ListView.view.width
                            height: 44
                            radius: 7
                            color: ListView.isCurrentItem
                                ? launcher.cSel
                                : resultMouse.containsMouse
                                    ? launcher.colors.cElevated : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                IconImage {
                                    implicitSize: 24
                                    source: Quickshell.iconPath(item.entry.icon, "application-x-executable")
                                }
                                Text {
                                    text: item.entry.name
                                    color: launcher.cText
                                    font.family: "sans-serif"
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: launcher.unifiedMode && !!item.entry.detail
                                    text: item.entry.detail
                                    Layout.maximumWidth: 180
                                    elide: Text.ElideMiddle
                                    font.family: "sans-serif"
                                    font.pixelSize: 10
                                    color: launcher.cDim
                                }

                                Text {
                                    visible: launcher.projectMode && launcher.pendingProject === ""
                                    text: item.entry.path || ""
                                    Layout.maximumWidth: 180
                                    elide: Text.ElideMiddle
                                    font.family: "sans-serif"
                                    font.pixelSize: 11
                                    color: launcher.cDim
                                }

                                Text {
                                    visible: launcher.windowMode
                                    text: item.entry.workspace
                                        ? "WS " + item.entry.workspace : ""
                                    Layout.maximumWidth: 80
                                    elide: Text.ElideRight
                                    font.family: "sans-serif"
                                    font.pixelSize: 11
                                    color: launcher.cDim
                                }

                                Text {
                                    visible: item.ListView.isCurrentItem
                                    text: "↵"
                                    color: launcher.cAccent
                                    font.pixelSize: 16
                                }
                            }

                            MouseArea {
                                id: resultMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton && item.entry.kind === "window")
                                        panel.closeWindow(item.entry)
                                    else panel.launch(item.entry)
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: launcher.projectMode
                            ? launcher.projectsLoading
                                ? "Chargement des projets…"
                                : panel.results.length === 0
                                    ? launcher.pendingProject !== ""
                                        ? "Aucun terminal correspondant · Échap Retour"
                                        : "Aucun projet correspondant dans Bureau ou Desktop"
                                    : launcher.pendingProject !== ""
                                        ? "↑↓ Choisir     ↵ Ouvrir     Échap Retour"
                                        : "↑↓ Choisir     ↵ Ouvrir dans un terminal     Échap Fermer"
                            : launcher.windowMode
                            ? panel.results.length === 0
                                ? "Aucune fenêtre correspondante · Échap Fermer"
                                : "↑↓ Choisir     ↵ Rejoindre     Échap Fermer"
                            : launcher.unifiedMode
                            ? panel.results.length === 0
                                ? "↵ Recherche web · youtube: pour YouTube · Échap fermer"
                                : "↑↓ Choisir     ↵ Ouvrir ou lancer une action     Échap Fermer"
                            : panel.results.length === 0
                            ? "↵ Recherche web · youtube: pour YouTube · Échap fermer"
                            : "↑↓ Choisir     ↵ Ouvrir     Échap Fermer"
                        font.family: "sans-serif"
                        font.pixelSize: 11
                        color: launcher.cDim
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
